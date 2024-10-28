@startuml
participant SDK as sdk
entity       Application       as app
entity    "Merchant Server"    as server
entity     Fazpass     as f

sdk --> app : Implementation
app -> sdk : Request Meta
sdk -> sdk : Generating Meta
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
        Challenge
    end note
    ||45||
    server -> f: Delete Other Device Request
    note right of server
        Fazpass Id
        Merchant App Id
        Meta
        Selected Device
        Challenge
    end note
    f-->server: Response
    note left of f
       status
    end note    
end
@enduml