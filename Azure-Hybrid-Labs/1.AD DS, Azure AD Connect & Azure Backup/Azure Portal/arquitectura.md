AD DS, Azure AD Connect & Azure Backup

Objetivo:
•	Diseñar y desplegar un entorno híbrido completo, creando una red que simula on prem y otra en cloud, ambas aisladas y conectadas mediante VPN Site to Site, para reproducir exactamente cómo se comunican las infraestructuras reales de las empresas.

•	Implementar Active Directory Domain Services en el entorno on prem, promoviendo un controlador de dominio, configurando DNS, creando usuarios, grupos y estructura organizativa, y unir un servidor remoto en la nube al dominio a través de la VPN, demostrando autenticación, resolución de nombres y tráfico de dominio en un entorno híbrido.

•	Configurar identidad híbrida con Azure AD Connect, sincronizando usuarios y grupos desde AD DS hacia Entra ID, validando la coexistencia de identidad local y cloud y mostrando cómo se integran ambos directorios en arquitecturas modernas.

•	Proteger el controlador de dominio on prem con Recovery Services Vault, instalando el MARS Agent, configurando backup de datos críticos, ejecutando un backup inicial y explicando cómo Azure Backup gestiona máquinas locales en escenarios híbridos.

•	Validar el entorno híbrido final, comprobando que el servidor cloud sigue autenticando contra el DC, que la conectividad VPN mantiene la comunicación entre redes, que la identidad híbrida continúa operativa y que queda establecido un marco de backup con un punto de recuperación.

1️. Crear grupo de recursos y redes
1.	Grupo de recursos
    o	rg-hybrid-lab
    o	Región: Spain Central

2.	VNet on prem (simulada)
    o	Nombre: vnet-onprem
    o	Address space: 10.10.0.0/24
    o	Subredes:
        	subnet-onprem → 10.10.0.0/26
        	AzureBastionSubnet → 10.10.0.64/26
        	GatewaySubnet → 10.10.0.128/26
En la creación de subnet-onprem y GatwaySubnet (Virtual Network Gatway), no marques Enable private subnet (no default outbound access); necesitas salida a internet.

3.	VNet cloud
    o	Nombre: vnet-cloud
    o	Address space: 10.20.0.0/24
    o	Subredes:
        	subnet-cloud → 10.20.0.0/26
        o	Creamos un NSG en subnet-cloud (nsg-subnet-cloud)
        	GatewaySubnet → 10.20.0.128/26
        	(Reserva) 10.20.0.192/26 para futuros PE
En la creación de subnet-onprem y GatwaySubnet (Virtual Network Gatway), no marques Enable private subnet (no default outbound access); necesitas salida a internet.

2️. Crear las máquinas virtuales
1.	DC01 (on prem)
    o	Name: dc01
    o	Image: Windows Server 2022 Datacenter.
    o	Size: B2ms.
    o	Username: DaniCloudTech
    o	Password: fuerte.
    o	Inbound ports: No
    o	Networking:
        1.	VNet: vnet-onprem
        2.	Subnet: subnet-onprem
        3.	Public IP: No
Después de crearla, en la NIC de dc01 cambia la IP privada a Static (ej. 10.10.0.4).
2.	SRV-CLOUD01 (cloud)
    o	Name: srv-cloud01
    o	Image: Windows Server 2022 Datacenter.
    o	Size: B2ms.
    o	Usuario: labadmin
    o	VNet: vnet-cloud
    o	Subnet: subnet-cloud
    o	Public IP: Si (Accederemos por RDP).

3.	Azure Bastion (solo en on prem)
    o	Name: bastion-hybrd-lab
    o	Availability Zone: None
    o	Tier: Standard
    o	Instance count: 2
    o	En vnet-onprem
    o	Subred: AzureBastionSubnet
    o	Grupo de recursos: rg-hybrid-lab
Configurar NICs con IP estática EN DC01 y SRV01 y regla NSG de subnet-cloud para acceso a SRV01

3. Configurar DC01 (AD DS + DNS)
1.Instalar roles en DC01
    •	AD DS
    •	DNS Server
2.Promocionar DC01 a controlador de dominio
    •	Nuevo bosque: dct.local
    •	DNS integrado
    •	Reinicio
3.Crear estructura básica de AD
    •	OU:
    o	DCT-Users
    o	DCT-Groups
    o	DCT-Servers
        •	Usuarios:
        o	UPN (User Principal Name) alternativo -> AD Domain and Trust -> AD Domain and Trust [DC01.dct.local] -> Properties -> custom domain/onmicrosoft.com -> Add
            	Crear usuario Admin y añadirlo a Domain Admins y Enterprise Admins
            	DCT\User1 -> Usar este nuevo UPN
            	DCT\User2 -> Usar este nuevo UPN
        •	Grupo:
            o	GG-Finanzas-Share en DCT-Groups con User1 dentro del grupo.

4.Crear carpeta de demo para backup
Crear C:\Departamentos\Finanzas.

4. Configurar VPN S2S entre las dos VNets  
    1.	Crear VPN Gateway en vnet-onprem  
        o	Nombre: gw-onprem  
        o	Tipo: VPN  
        o	SKU: VpnGw1 (o similar)  
        o	Subred: GatewaySubnet (10.10.0.128/26)  
En un entorno real, el gateway on prem no es un Azure VPN Gateway, sino un router o firewall físico/virtual que se configura manualmente con la IP pública del Azure VPN Gateway, las redes internas de Azure y la clave compartida. El extremo de Azure es exactamente igual que en este laboratorio.  

    2.	Crear VPN Gateway en vnet-cloud  
        o	Nombre: gw-cloud  
        o	Tipo: VPN  
        o	SKU: VpnGw1  
        o	Subred: GatewaySubnet (10.20.0.128/26)  
Esperar a que ambos gateways se creen (tardan).  
    3.	Obtener las IP públicas de ambos gateways  
        o	gw-onprem → IP pública A  
        o	gw-cloud → IP pública B  
    4.	Crear Local Network Gateway para cada lado  
    •	En on prem:  
        o	Nombre: lng-onprem-cloud  
        o	IP pública: la de gw-cloud  
        o	Address space remoto: 10.20.0.0/24  
    •	En cloud:  
        o	Nombre: lng-cloud-onprem  
        o	IP pública: la de gw-onprem  
        o	Address space remoto: 10.10.0.0/24  

5.	Crear conexión S2S en cada gateway
    •	En gw-onprem:
        o	Conexión: conn-onprem-to-cloud
        o	Tipo: Site-to-site (IPSec)
        o	Local Network Gateway: lng-cloud
        o	Shared key: la misma en ambos lados (ej. HybridLab123!)
    •	En gw-cloud:
        o	Conexión: conn-cloud-to-onprem
        o	Tipo: Site-to-site (IPSec)
        o	Local Network Gateway: lng-onprem
        o	Shared key: HybridLab123!

6.	Validar la conexión
    •	Estado de ambas conexiones: Connected
    •	Desde dc01: ping 10.20.0.4 (IP de srv-cloud01).
        o	En srv-cloud01:
        o	Abre
        o	Windows Defender Firewall with Advanced Security
        o	Ve a
        o	Inbound Rules
        o	Busca y habilita estas dos reglas:
        o	File and Printer Sharing (Echo Request – ICMPv4-In)
        o	File and Printer Sharing (Echo Request – ICMPv4-Out) (opcional)
        o	Vuelve a probar desde dc01:ping 10.20.0.4
    •	Desde srv-cloud01: ping 10.10.0.4 (IP de dc01).
Ahora sí tienes un entorno híbrido real, con VPN S2S entre “on prem” y “cloud”.

7.	Unir SRV01 al dominio (a través de la VPN)
    7.1. Cambia el DNS de srv-cloud01 (muy importante)
        •	En srv-cloud01:
        •	Abre Network & Internet Settings
        •	Cambia el adaptador de red
        •	Propiedades → IPv4
        •	Pon como DNS 10.10.0.4 (tu DC on prem)
        •	Sin esto, no podrá encontrar el dominio.
        •	Prueba: nslookup dc01.dct.local

    7.2. Unir srv-cloud01 al dominio
        •	En srv-cloud01:
        •	Botón derecho en el botón de Start
        •	Pulsa System
        •	En la ventana de System, a la derecha, haz clic en:
        •	“Rename this PC (advanced)”
        •	Se abrirá la ventana clásica de System Properties.
        •	Cambiar de Workgroup a Domain
        •	En la ventana de System Properties:
        •	Pestaña Computer Name
        •	Pulsa el botón Change…
        •	En la sección Member of, selecciona:
        •	Marca Domain
        •	Escribe: DCT.local
        •	Pulsa OK
        •	Introducir credenciales del dominio
        •	Te aparecerá una ventana pidiendo usuario y contraseña.
        •	Pon:
        •	User name: DCT\Administrador
        •	Password: la contraseña del Administrador del dominio
        •	Pulsa OK.
        •	Aparecerá un mensaje de bienvenida al dominio

Comprobación:
    •	En AD, ver srv-cloud01 en Computers (mover a DCT-Servers).
    •	Iniciar sesión en srv-cloud01 con usuario de dominio.
            o	Entrar en remote settings y añadir el grupo al que pertenece user1 (GG-Finanzas) o User1
El server en cloud está unido al dominio on prem a través de la VPN S2S.

8.	Configurar Azure AD Connect en SRV01
    8.1. Preparar Entra ID
        •	Tenant listo
        •	Dominio onmicrosoft.com o custom
    8.2.Instalar Azure AD Connect en SRV01
        •	Ponemos en buscador entra.microsoft.com e iniciamos sesión
        •	Descargar desde Microsoft Entra Admin Center
        •	Microsoft Entra Connect > Manage > Download Connect Sync Agent (AzureADConnect.msi)
        •	Modo: Password Hash Sync
        •	Seleccionar OU de usuarios
    8.3.Validar sincronización
        •	Ver usuarios de dct.local en Entra ID
        •	Comprobar estado de AD Connect

9.	Configurar Recovery Services Vault en DC01
    9.1.Crear Recovery Services Vault
        •	rsv-hybrid-lab
        •	Misma región
        •	rg-hybrid-lab
    8.2.Configurar backup para DC01
        •	“Backup” → “Backup goal”
        •	Workload: “On-premises”
        •	Descargar MARS Agent
    8.3.Instalar MARS Agent en DC01
    o	Poner Vault Credentials (descargar desde el portal)
    o	Crear Key Vault
        	Azure role-based access control (recommended)
    o	Asignar Identidad Administrada a RSV:
        	RSV > Settings > Identity > System Assigned > On
    o	Add Role Assigment: Operator Nexus Key Vault Writer Service Role (Preview)
    o	Indicar URI del Key Vault: https:// “nombrevault”.vault.azure.net/
    9.1.Configurar política y ejecutar backup inicial
        •	Frecuencia diaria
        •	Lanzar backup
        •	Lanzar Backup Now
        •	Ver punto de recuperación
10.	Validación final
    1.Identidad híbrida
        •	AD DS on prem (simulado) → Entra ID
        •	AD Connect funcionando
        •	SRV01 unido al dominio
    2.Conectividad híbrida
        •	VPN S2S entre vnet-onprem y vnet-cloud
        •	Tráfico fluye entre DC y server
    3.Backup
        •	DC01 protegido en RSV
