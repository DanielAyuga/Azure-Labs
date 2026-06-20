Control de tráfico saliente con Azure Firewall Basic + Firewall Policy + UDR + DNS

Índice:
Objetivo del laboratorio
1. Crear el Resource Group
2. Crear la VNet y las subnets
3. Crear Log Analytics Workspace
4. Crear la VM en la subnet Workload-SN
5. Crear Azure Firewall Basic + Firewall Policy
6. Crear la Route Table (UDR)
7. Configurar la Firewall Policy (Zero Trust)
7.1. Network Rule Collection → Permitir DNS
7.2. Application Rule Collection → Permitir solo ciertos FQDNs
8. Configurar Diagnostic Settings del Firewall
9. Pruebas desde la VM
9.1. Probar bloqueo general
9.2. Probar acceso permitido
9.3. Probar DNS
10. Consulta en Log Analytics
RESUMEN FINAL

Objetivo del laboratorio
Simular un escenario real donde una empresa quiere que ninguna VM pueda salir directamente a Internet. Todo el tráfico debe pasar por un Azure Firewall, donde se aplican reglas de seguridad centralizadas (Zero Trust) y se registran en Log Analytics.


1. Crear el Resource Group
Nombre: rg-azfw-lab
Región: spaincentral
Acotación: Mantener todo en la misma región evita problemas de latencia y compatibilidad.


2. Crear la VNet y las subnets
VNet: vnet-azfw-lab
Address space: 10.0.0.0/24
Subnets obligatorias:
•	workload-snet → 10.0.0.0/26 Aquí va la VM. Por defecto tiene salida a Internet gracias a las rutas del sistema y al NSG. Luego lo romperemos con la UDR.
•	AzureBastionSubnet → 10.0.0.64 /26 Nombre obligatorio. Aquí vive Bastion.
•	AzureFirewallSubnet → 10.0.0.128 /26 Nombre obligatorio. Aquí vive el Firewall.
•	AzureFirewallManagementSubnet → 10.0.0.192/26 Obligatoria para Azure Firewall Basic. Gestión separada del dataplane.


3. Crear Log Analytics Workspace
Nombre: law-azfw-lab
Región: spaincentral
Acotación: El Firewall no tiene sentido sin logs. En empresas, el SOC depende de esto.


4. Crear la VM en la subnet Workload-SN
Nombre: vm-workload-01
Subnet: Workload-SN
IP pública: No (Acceso por Bastion)
Puertos públicos: No (Acceso por Bastion)
Acotación importante: Por defecto, la VM sí tiene salida a Internet, porque:
•	Las rutas del sistema incluyen 0.0.0.0/0 → Internet
•	El NSG por defecto permite outbound Esto es lo que vamos a romper con la UDR.


5. Crear el recurso Azure Bastion
Aquí es donde enlazas la VNet, la subnet y la IP pública.
•	Ve a Create a resource → Networking → Bastion
•	Resource group: rg-azfw-lab
•	Nombre: bastion-azfw-lab
•	Región: misma que la VNet
•	En Virtual network, selecciona vnet-azfw-lab
•	En Subnet, elige AzureBastionSubnet
•	En Public IP address, crear nueva
•	Revisa y pulsa Create

6. Crear Azure Firewall Basic + Firewall Policy
Firewall:
•	Nombre: azfw-basic-lab
•	SKU: Basic
•	VNet: vnet-azfw-lab
•	Subnet: AzureFirewallSubnet
•	Management subnet: AzureFirewallManagementSubnet
•	Public IP: Create New
Firewall Policy:
•	Nombre: azfw-policy-lab
•	Tipo: Firewall Policy (no reglas locales)
•	Región: Spain Central
Acotación:
•	No uses reglas locales del Firewall → están en desuso.
•	Firewall Policy es el estándar moderno.
•	No uses Firewall Premium → caro y no necesario.


7. Crear la Route Table (UDR)
Nombre: rt-azfw-lab
Región: spaincentral
Añadir la ruta:
•	Route name: default-to-firewall
•	Address prefix: 0.0.0.0/0
•	Next hop type: Virtual appliance
•	Next hop address: IP privada del Firewall (ej. 10.0.0.128)
Asociar la UDR a la subnet de la VM:
•	Subnet: Workload-SN
Acotación CRÍTICA: La UDR no necesita ninguna regla NSG para funcionar. El orden de procesamiento es:
    1.	UDR decide el camino
    2.	NSG decide si se permite
    3.	Firewall inspecciona
    La UDR obliga a que todo el tráfico vaya al Firewall. El NSG no decide el destino, solo permite o bloquea.


8. Configurar la Firewall Policy (Zero Trust)
    8.1. Network Rule Collection → Permitir DNS
        Nombre: net-allow-dns Priority: 100 Action: Allow Rule:
        •	Name: allow-dns-azure
        •	Source: 10.0.0.0/26
        •	Protocol: UDP
        •	Destination port: 53
        •	Destination: 168.63.129.16 (Azure DNS)
        Acotación:
        •	Sin DNS, la VM no puede resolver dominios.
        •	Sin resolución, las Application Rules NO funcionan.
        •	Esto demuestra control total del tráfico, incluso DNS.
    8.2. Application Rule Collection → Permitir solo ciertos FQDNs
        Nombre: app-allow-web Priority: 200 Action: Allow
        Rule:
        •	Name: allow-ms-sites
        •	Source: 10.0.0.0/26
        •	Protocol: Http, Https
        •	Destination type: FQDN
        •	FQDNs:
        o	learn.microsoft.com
        o	www.microsoft.com
        o	docs.microsoft.com
        Acotación:
        •	Una sola regla con varios FQDNs es suficiente.
        •	Todo lo que no esté aquí → bloqueado.


9. Configurar Diagnostic Settings del Firewall
Dentro de Firewall>Monitoring>Diagnostic Settings -> Enviar logs a Log Analytics:
•	AzureFirewallApplicationRule
•	AzureFirewallNetworkRule
•	AzureFirewallDnsProxy
Acotación: Esto es lo que permite ver tráfico permitido/denegado. En empresas, esto es obligatorio.


10. Pruebas desde la VM
    10.1. Probar bloqueo general
        https://google.com
        https://github.com
        Resultado esperado: bloqueado En logs: Deny
    10.2. Probar acceso permitido
        https://learn.microsoft.com
        https://www.microsoft.com
        Resultado esperado: permitido En logs: Allow
    9.3. Probar DNS
        PowerShell
        nslookup learn.microsoft.com
        Resultado esperado: resolución correcta En logs: tráfico DNS permitido
11. Consulta en Log Analytics
Dentro del Log Analytics Workspace>Logs>Tablas

Acotación: Aquí ves:
•	IP origen
•	Destino
•	Regla aplicada
•	Allow/Deny
•	Puerto/protocolo


12. RESUMEN FINAL
Por defecto, una VM en Azure tiene salida a Internet gracias a las rutas del sistema y al NSG. En este laboratorio rompemos ese comportamiento con una UDR que obliga a que todo el tráfico pase por Azure Firewall Basic. La Firewall Policy aplica Zero Trust: todo está bloqueado excepto lo que permitimos explícitamente. Incluso DNS pasa por el Firewall. Esto es exactamente cómo una empresa controla el tráfico saliente de sus workloads en Azure.”