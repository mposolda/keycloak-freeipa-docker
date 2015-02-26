FROM adelton/freeipa-server:fedora-20

RUN yum install -y unzip && yum clean all

RUN mkdir /keycloak-work
ADD freeipa-realm.json /keycloak-work/freeipa-realm.json
ADD keycloak-freeipa-trigger.sh /keycloak-work/keycloak-freeipa-trigger.sh

RUN chmod -v +x /keycloak-work/keycloak-freeipa-trigger.sh

ENTRYPOINT /keycloak-work/keycloak-freeipa-trigger.sh


