FROM adelton/freeipa-server:fedora-20

RUN yum install -y unzip && yum clean all

RUN mkdir /keycloak-work
ADD appliance-dist /keycloak-work/appliance-dist
ADD freeipa-realm.json /keycloak-work/freeipa-realm.json
ADD keycloak-freeipa-trigger.sh /keycloak-work/keycloak-freeipa-trigger.sh

RUN cd /keycloak-work ; unzip -q /keycloak-work/appliance-dist/keycloak-appliance-dist*.zip ; mv /keycloak-work/keycloak-appliance-dist*/keycloak kc
RUN chmod -v +x /keycloak-work/keycloak-freeipa-trigger.sh

ENTRYPOINT /keycloak-work/keycloak-freeipa-trigger.sh


