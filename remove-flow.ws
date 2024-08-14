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
    server -> f: Check Request
    note right of server
        Meta
        PIC Id
        Merchant App Id
        Merchant Key (Header)
    end note
    f-->server: Response
    note left of f
        fazpass id
        challenge
    end note
    ||45||
    server -> f: Remove Request
    note right of server
        Meta
        Fazpass Id
        Merchant App Id
        Challenge
        Merchant Key (Header)
    end note
    f-->server: Response
    note left of f
        removed detail
    end note    
end
@enduml