# Localization of both members and people

## Localization of network members
### Membership
The principle behind creating a network of trusted members is selecting a Trusted Third Party that acts as gatekeeper to allow members on the network. Alongside, these memberships reflect the capabilities, such as `openEHR` and profiles, such as `ACP`.

Preferably, those memberships are founded by a trusted publicly issued attribute such as an URA number from CIBG.

![ttp_membership.puml](ttp_membership.png)

### Registration & discovery

In order to keep track of the members in a network one or more registers are selected. Each member in the network registers itself at the registration endpoint by presenting a VP proving the membership. The registry periodically queries each member using ths Oid4VP protocol to affirm the members active status in the network. This register affords a form of discovery, as all members in the network are available in a database. This enables members of the network to run queries on the database. 

![discovery.puml](discovery.png)

The register follows the pattern as described  by NUTS as part of the [discovery pattern](https://nuts-node.readthedocs.io/en/latest/pages/deployment/discovery.html).

### Querying for services
The network can be queried on their services. These queries are defined by the NUTS openapi specification.

### Example query
```cURL
GET /internal/discovery/v1/OpenEhrOrgCredential?query=credentialSubject.capabilities=openEHR&profiles=ACP
```
### 


