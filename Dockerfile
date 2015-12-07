FROM adelton/freeipa-server:fedora-20

RUN mkdir /keycloak-work
ADD keycloak-dist /keycloak-work/keycloak-dist
ADD freeipa-realm.json /keycloak-work/freeipa-realm.json
ADD keycloak-freeipa-trigger.sh /keycloak-work/keycloak-freeipa-trigger.sh

RUN chmod -v +x /keycloak-work/keycloak-freeipa-trigger.sh

ENTRYPOINT /keycloak-work/keycloak-freeipa-trigger.sh


