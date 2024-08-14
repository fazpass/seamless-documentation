@startuml
entity       "Application \n (Trusted Device)"      as appt
participant SDK as sdk
entity       "Application \n (Untrusted Device)"       as app
entity    "Merchant Server"    as server
entity     Fazpass     as f
sdk--> appt : Implementation
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
        notifiable devices
    end note
    ||45||
    server -> f: Send Notification
    note right of server
        Meta
        PIC ID
        Merchant App Id
        Selected Device
        Merchant Key (Header)
    end note
    f-->server: Response
    note left of f
        notification status
    end note
end
f->sdk: Send Notification
note left of f
notification id
end note
sdk->appt : Pop Notification (Allow/Reject)
appt->sdk : Request Meta
sdk -> sdk : Pop Biometric & Generating Meta
sdk --> appt:
note left of sdk 
Meta
end note
appt->server : Sending Meta & Result
alt White Listed IP
server->f: Validate Notification
    note right of server
        Meta
        Notification Id
        Result
        Merchant App Id
        Merchant Key (Header)
    end note
f-->server: Response
    note left of f
        notification status
    end note
end
@enduml