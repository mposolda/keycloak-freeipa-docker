Keycloak and FreeIPA docker image
=================================

This docker image will setup FreeIPA environment on Fedora 20 and add some example users to FreeIPA. 

Image also contains Keycloak server and it will configure it to use FreeIPA LDAP server as Federation provider and it will enable Kerberos/SPNEGO authentication for Keycloak. In order to participate in Kerberos/SPNEGO you still need to do few steps on your laptop - configure Kerberos client and web browser.

In order to have the image running, you need to do these steps:

Building docker image
---------------------
If you want, you can build docker image by yourself. But you can skip this step and use pre-builded image `mposolda/keycloak-freeipa-server:1.9.0.CR1` . If you're going to build it by yourself you need to:

**1** Download keycloak-demo TAR.GZ distribution of version 1.9.0.CR1 or newer and put this TAR.GZ file to subdirectory `keycloak-dist`

**2** Copy directory with OpenJDK8 to `keycloak-dist` directory under path `openjdk8` . Assumption is that `keycloak-dist/openjdk8/bin/java` is java executible.

**3)**  Install docker on your laptop if you not already have it. Then if you want, you can build docker image by yourself with command:

```
docker build -t keycloak-freeipa-server .
```

So if you followed this and build the image by yourself, replace image name `mposolda/keycloak-freeipa-server:1.9.0.CR1` with your name `keycloak-freeipa-server` in later steps. 


Running docker image
--------------------

**1)** Install docker on your laptop if you not already have it. Then run docker image `mposolda/keycloak-freeipa-server:1.9.0.CR1`. You need to expose kerberos ports 
and also HTTP port of Keycloak server. It's also good to expose LDAP server port (so you can connect remotely to LDAP) and Keycloak debugger port (if you want remote Keycloak debugging 
from your IDE).

Also you can add some stuff to directory `/tmp/ipa-data` if you want. See [https://github.com/adelton/docker-freeipa/blob/fedora-20/README](https://github.com/adelton/docker-freeipa/blob/fedora-20/README) for details. 

More lines are just for easier readability, but whole command should be single line:

```
docker run --name keycloak-freeipa-server-container -ti -h ipa.example.test 
-e PASSWORD=Secret123 -v /tmp/ipa-data/data -p 20088:88 -p 20088:88/udp -p 29080:9080 
-p 20389:389 -p 28787:8787 mposolda/keycloak-freeipa-server:1.9.0.CR1
```

If you want to access FreeIPA admin console, you may expose also port 80 and 443, but it seems that you need to expose them "unmapped" to your machine. Hence you
will need to run above command with `sudo` and make sure the ports 80 and 443 are free on your machine (no Apache HTTPD or other web server running on your local machine). So then you can use:
```
-p 80:80 -p 443:443
```
 
**2)** You will need to access keycloak via `ipa.example.test` server as this matches to HTTP service kerberos principal. In linux you can just put this line to `/etc/hosts` file (on your machine, not docker container):

```
127.0.0.1   ipa.example.test
```

**3)** If you want your web browser to participate in Kerberos authentication, you need to configure Kerberos client. You should first install Kerberos client on your machine. This is platform dependent, so consult documentation of your OS on how to do it. On Fedora, Ubuntu or RHEL you can install just package `freeipa-client`, which installs kerberos client, LDAP client and bunch of other stuff. 

Once client is installed, you can configure Kerberos client configuration file (on Linux it's in `/etc/krb5.conf` ) similarly like this:

```
[libdefaults]
  default_realm = EXAMPLE.TEST
  dns_lookup_realm = false
  dns_lookup_kdc = false
  rdns = false
  ticket_lifetime = 24h
  forwardable = yes

[realms]
  EXAMPLE.TEST = {
    kdc = ipa.example.test:20088
  }

[domain_realm]
  .example.test = EXAMPLE.TEST
  example.test = EXAMPLE.TEST  
```

**4)** Finally configure your browser to participate in Kerberos/SPNEGO authentication flow. You need to allow domain `ipa.example.test` to be trusted. Exact steps are again browser dependent. 

For Firefox see for example [https://www.adelton.com/docs/idm/enable-kerberos-in-firefox](https://www.adelton.com/docs/idm/enable-kerberos-in-firefox) . URI `ipa.example.test` must be allowed in `network.negotiate-auth.trusted-uris` config option. 

For Chrome, you just need to run the browser with command similar to this (more details in Chrome documentation):

```
/usr/bin/google-chrome-stable --auth-server-whitelist="ipa.example.test"
```

**5)** Test the integration. First ensure that you have Kerberos ticket available for the FreeIPA EXAMPLE.TEST kerberos realm. In many OS you can achieve this by running command from CMD like:

```
kinit hnelson@EXAMPLE.TEST
```

and provide password `Secret123`

You can check with:
```
klist
```

that you have ticket for user `hnelson`

Now you can simply visit this URL from your browser [http://ipa.example.test:29080/auth/realms/freeipa/account/](http://ipa.example.test:29080/auth/realms/freeipa/account/) and you should 
be logged in automatically as `hnelson` user in Keycloak account management.

Other testing users are:
`jduke` with password `Secret123` or `admin` with password `Secret123` (as long as you didn't change PASSWORD variable in "docker run" command above) .

To check the configuration of federation provider, go to [http://ipa.example.test:29080/auth/admin](http://ipa.example.test:29080/auth/admin) , login as admin/admin and verify how is Federation provider configured.
You can also click `Sync all users` to sync all FreeIPA users into Keycloak (otherwise they are synced during their first login).

The Federation provider is configured to be WRITABLE, which means that updating any attribute of user in Keycloak (For example changing firstName of user `hnelson` to `Homer` ) will be propagated to LDAP as well.
However registration of new users in Keycloak FreeIPA realm won't add users to FreeIPA LDAP, because `syncRegistration` flag is disabled on Federation provider configuration.
 
Among other mappers, you can see `IPA groups mapper` configured for federation provider. This maps FreeIPA groups from `cn=groups,cn=accounts,dc=example,dc=test` to Keycloak realm roles of `freeipa` realm.
Creating new role in Keycloak will create new Group into FreeIPA LDAP as well. Also create/remove any membership from Keycloak should work as expected. 

Mappers are configured the way, so that when changing things on FreeIPA/LDAP side, the changes should be immediatelly visible on Keycloak side too.
 
 

**6** You can stop the docker container by running command:
```
exit
```

from the interactive terminal with docker. Then to start it again, you can use:
```
docker start -ai keycloak-freeipa-server-container
```

The startup will be quite fast as FreeIPA and Keycloak setup are already finished now.






