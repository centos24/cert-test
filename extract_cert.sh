#!/bin/bash

CACERTS_PATH="./cacerts"
KEYTOOL="./java/bin/keytool"
STOREPASS="test"
ALIAS="alias-name"

if [[ ! -f "$CACERTS_PATH" ]]; then
  echo "Error: Not found file '$CACERTS_PATH'" >&2
  exit 1
fi

map_algosign() {
  local sig="$1"
  case "$sig" in
    SHA256withECDSA) echo "ecdsa-with-SHA256" ;;
    SHA384withECDSA) echo "ecdsa-with-SHA384" ;;
    SHA512withECDSA) echo "ecdsa-with-SHA512" ;;
    SHA1withECDSA)   echo "ecdsa-with-SHA1" ;;
    SHA256withRSA)   echo "sha256WithRSAEncryption" ;;
    SHA384withRSA)   echo "sha384WithRSAEncryption" ;;
    SHA512withRSA)   echo "sha512WithRSAEncryption" ;;
    SHA1withRSA)     echo "sha1WithRSAEncryption" ;;
    MD5withRSA)      echo "md5WithRSAEncryption" ;;
    *)
      if [[ "$sig" =~ ^SHA([0-9]+)with(ECDSA|RSA)$ ]]; then
        local bits="${BASH_REMATCH[1]}"
        local ktype="${BASH_REMATCH[2]^^}"
        if [[ "$ktype" == "ECDSA" ]]; then
          echo "ecdsa-with-SHA${bits}"
        else
          echo "sha${bits}WithRSAEncryption"
        fi
      else
        echo "$sig"
      fi
      ;;
  esac
}

json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

if ! cert_info="$(LC_ALL=C $KEYTOOL -list -v \
  -alias "$ALIAS" \
  -keystore "$CACERTS_PATH" \
  -storepass "$STOREPASS" 2>/dev/null)"; then
  echo "Error: Not found alias '$ALIAS' z '$CACERTS_PATH'" >&2
  exit 1
fi

owner="$(printf '%s\n' "$cert_info" | awk -F': ' '/^Owner:/ { sub(/\r$/, "", $2); print $2; exit }')"
issuer="$(printf '%s\n' "$cert_info" | awk -F': ' '/^Issuer:/ { sub(/\r$/, "", $2); print $2; exit }')"
sig_alg="$(printf '%s\n' "$cert_info" | awk -F': ' '/^Signature algorithm name:/ { sub(/\r$/, "", $2); print $2; exit }')"

valid_line="$(printf '%s\n' "$cert_info" | awk '/^Valid from:/ { sub(/^Valid from:[[:space:]]*/, ""); sub(/\r$/, ""); print; exit }')"
if [[ -z "$valid_line" || "$valid_line" != *" until: "* ]]; then
  echo "Error: Not found line 'Valid from' for alias '$ALIAS'" >&2
  exit 1
fi

start_str="${valid_line%% until: *}"
end_str="${valid_line#* until: }"

starts="$(date -u -d "$start_str" +%s)"
expires="$(date -u -d "$end_str" +%s)"


owner_clean="$(printf '%s' "$owner" | sed -E 's/,[[:space:]]+/,/g')"
subj_with_alias="${owner_clean}, alias: ${ALIAS}"
issuer_clean="$(printf '%s' "$issuer" | sed -E 's/,[[:space:]]+/,/g')"
algosign="$(map_algosign "$sig_alg")"

echo '<<<sslcertificates:sep(0)>>>'

printf '{"file": "%s", "starts": %s, "expires": %s, "algosign": "%s", "issuer_hash": "", "issuer": "%s", "subj": "%s", "subjAltName": []}\n' \
  "$(json_escape "$CACERTS_PATH")" \
  "$starts" \
  "$expires" \
  "$(json_escape "$algosign")" \
  "$(json_escape "$issuer_clean")" \
  "$(json_escape "$subj_with_alias")"
