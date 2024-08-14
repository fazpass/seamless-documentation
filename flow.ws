@startuml
participant SDK as sdk
entity       Application       as app
entity    "Merchant Server"    as server
entity     Fazpass     as f

sdk --> app : Implementation
app -> sdk : Request Meta
sdk -> sdk : Pop Biometric & Generating Meta
sdk --> app :
note right of sdk
Meta
end note
app->server : Sending Meta
alt White Listed IP
    server -> f: Action Request
    note right of server
        Meta
    end note
    f-->server: Response
    note left of f
        Data Detail
    end note    
end
@enduml