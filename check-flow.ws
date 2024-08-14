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
        Fazpass Id
        Is Active
        Platform
        Rooted Status
        Emulator Status
        GPS Spoof Status
        App Tempering Status
        VPN Status
        Clone App Status
        Screen Sharing Status
        Debug Status
        Enrolled Device
        Device Information
        (Name, Series, CPU, OS Version)
        Sim Serial
        Sim Operator
        Geolocation
        (Latitude, Longitude, Distance, Time)
        Client IP
        Notifiable Device
        Biometric Level
        Biometric Change Status
        Enrolled Device
        Challenge
    end note    
end
@enduml