#!/bin/bash

echo "keycloak-freeipa-trigger.sh: Executed";

sed -i -e 's/[^!]\/bin\/bash/#\/bin\/bash/' /usr/sbin/ipa-server-configure-first
sed -i -e 's/while true/#while true/' /usr/sbin/ipa-server-configure-first
sed -i -e 's/trap/#trap/' /usr/sbin/ipa-server-configure-first

echo "Registering trap signals";

function stop_running () {
	systemctl stop-running
	exit
}
trap exit TERM
trap stop_running EXIT


echo "keycloak-freeipa-trigger.sh: Running ipa-server-configure-first";

/usr/sbin/ipa-server-configure-first

echo "keycloak-freeipa-trigger.sh: ipa-server-configure-first finished";

echo $PASSWORD | kinit admin
if ipa user-find hnelson; then
   kdestroy
   echo "keycloak-freeipa-trigger.sh: Example users hnelson and jduke already exists. Skip adding them";   
else 
   ipa user-add hnelson --first=Horatio --last=Nelson
   echo "Temp123
   Temp123" | ipa passwd hnelson
   echo "Temp123
Secret123
Secret123" | kinit hnelson
   kdestroy

   echo $PASSWORD | kinit admin
   ipa user-add jduke --first=Java --last=Duke
   echo "Temp123
   Temp123" | ipa passwd jduke
   echo "Temp123
Secret123
Secret123" | kinit jduke
   kdestroy

   echo "keycloak-freeipa-trigger.sh: Example users hnelson and jduke added to freeipa";
fi;


export HOST=$(hostname -f)
export LDAP_BASE_DN=$(hostname -f | sed s/[^\\.]*\\././ | sed s/\\./,dc=/g | sed s/,//)
export KERBEROS_REALM=$(cat /etc/krb5.conf | grep default_realm | awk -F"default_realm.=." '{print  $2 }')

echo "keycloak-freeipa-trigger.sh: PASSWORD=$PASSWORD, KERBEROS_REALM=$KERBEROS_REALM, HOST=$HOST, LDAP_BASE_DN=$LDAP_BASE_DN";

cat /keycloak-work/freeipa-realm.json | 
sed -i -e "s/\${ldapBaseDn}/$LDAP_BASE_DN/" /keycloak-work/freeipa-realm.json
sed -i -e "s/\${host}/$HOST/" /keycloak-work/freeipa-realm.json
sed -i -e "s/\${kerberosRealm}/$KERBEROS_REALM/" /keycloak-work/freeipa-realm.json
sed -i -e "s/\${password}/$PASSWORD/" /keycloak-work/freeipa-realm.json

echo "keycloak-freeipa-trigger.sh: File formatting finished. Final file: ";
cat /keycloak-work/freeipa-realm.json

# Done here instead of in Dockerfile just due to size of the image
if ls /keycloak-work/keycloak-appliance-dist* ; then
  echo "keycloak-freeipa-trigger.sh: Keycloak already prepared. Skip preparing";
else
  echo "keycloak-freeipa-trigger.sh: Preparing keycloak";
  cd /keycloak-work 
  unzip -q /keycloak-work/appliance-dist/keycloak-appliance-dist*.zip 
  mv /keycloak-work/keycloak-appliance-dist*/keycloak kc
fi;

echo "keycloak-freeipa-trigger.sh: Running keycloak";
cd /keycloak-work/kc/bin
./standalone.sh -b 0.0.0.0 -Djboss.http.port=9080 -Dkeycloak.import=/keycloak-work/freeipa-realm.json &


if [ -t 0 ] ; then
  echo 'keycloak-freeipa-trigger.sh: Starting interactive shell.'
  /bin/bash
else
  echo 'keycloak-freeipa-trigger.sh: Go loop.'
  while true ; do sleep 1000 & wait $! ; done
fi
