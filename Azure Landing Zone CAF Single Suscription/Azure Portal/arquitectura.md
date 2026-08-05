Creación de Azure Landing Zone CAF Single Suscription (manualmente):  

1. Crear Management Groups “DaniCloudTech”  
Debajo del MG Root crearemos el MG DaniCloudTech que será nuestro MG a nivel empresarial. 
Pasos:
•	mg-root → Add management group:  
2. Mover la suscripción a “DaniCloudTech” 
Muevo la suscripción a DaniCloudTech. 
Pasos: 
1.	Subscriptions → seleccionar tu suscripción 
2.	Move → elegir mg-danicloudtech 
3.	Verificar que aparece bajo mg-danicloudtech 
3. Crear usuarios en Entra ID 
Creo las cuentas de ejemplo que usaremos: adminpm, operaciones, networking, seguridad y desarrollo.”  
Usuarios: 
•	dani.admin@danicloudtech.com → Dani Admin 
•	maria.pm@danicloudtech.com → Maria PM 
•	ana.ops@danicloudtech.com → Ana Ops 
•	carlos.net@danicloudtech.com → Carlos Net 
•	lucia.sec@danicloudtech.com → Lucia Sec 
•	david.dev@danicloudtech.com → David Dev  
Nota: MFA para cuentas privilegiadas lo activaremos con Conditional Access si no tienes habilitado en la suscripción la opción Entra ID > Authentication Methods > Microsoft Authenticator > All users > Yes  
4. Crear grupos de seguridad 
Creamos grupos de seguridad para asignar permisos por rol. Nunca asignamos roles directamente a usuarios.  
Grupos: 
•	GRP-DaniCloudTech-Admins 
•	GRP-Platform-Network-Admins 
•	GRP- Platform-Identity-Admins 
•	GRP- Platform-Management-Admins 
•	GRP- Platform-Security-Admins 
•	GRP-LZ-Dev-Contributor 
•	GRP-LZ-Test- Contributor 
•	GRP-LZ-Prod- Contributor 
•	GRP-Sandbox-Owners  
5. Crear Resource Groups 
Creamos los RGs; aquí es donde cada dominio técnico tendrá sus recursos.” 
RGs:  
•	RG-Platform-Identity 
•	RG-Platform-Networking 
•	RG-Platform-Security 
•	RG-Platform-Management 
•	RG-LZ-Dev 
•	RG-LZ-Prod 
•	RG-LZ-Test 
•	RG-Sandbox  
6. Asignaciones grupo-usuario y rol-RG: 
GRP-DaniCloudTech-Admins 
•	Miembro: Maria PM 
•	Rol: Owner en mg-danicloudtech 
GRP-Platform-Identity-Admins 
•	Miembro: Ana Ops 
•	Rol: Owner en rg-platform-identity 
GRP- Platform-Network-Admins 
•	Miembro: Carlos Net 
•	Rol: Owner en rg-platform-networking 
GRP-Platform-Security-Admins 
•	Miembro: Lucia Sec 
•	Rol: Owner en rg- platform-security 
GRP-Platform-Management-Admins 
•	Miembros: Ana Ops 
•	Rol: Owner en rg-platform-management 
GRP-Dev-Admins 
•	Miembro: David Dev 
•	Rol: Contributor en rg-lz-dev 
GRP-Test-Admins 
•	Miembro: David Dev 
•	Rol: Contributor en rg-lz-test 
GRP-Prod-Admins 
•	Miembro: Lucia Sec 
•	Rol: Contributor en rg-lz-prod  
7. Políticas básicas por dominio 
7.1. MG DaniCloudTech (Gobernanza global) 
Aquí van solo las políticas que afectan a toda la suscripción. 
Políticas globales (no se repiten en los RGs) 
-Allowed locations 
Propósito: evitar despliegues fuera de la/las localizaciones seleccionadas. 
Fin: cumplimiento y orden.  
-Enforce Diagnostic Settings to Log Analytics (TODOS los recursos) 
Propósito: garantizar que absolutamente todo envía logs al LAW. 
Fin: seguridad, auditoría, troubleshooting.   
-Azure Security Benchmark
Propósito: Establecer un conjunto de controles de seguridad estandarizados 
Fin: Evaluar, medir y mejorar continuamente la postura de seguridad  
-Audit resources without diagnostic settings 
Propósito: detectar recursos sin logs. 
Fin: seguridad.  
Despliegue: 
1.	Accedes al management group 
2.	Settings > Policies 
3.	Add New Policy  
7.2. RG Platform Security  
Este RG solo tendrá un recurso 
Recursos: 
•	Key Vault principal (KV Platform Security) 
Políticas específicas del RG 
-Key vaults should have purge protection enabled 
Propósito: evitar borrados maliciosos.Fin: seguridad. 
-Key vaults should use RBAC permission model 
Propósito: evitar políticas antiguas de acceso. Fin: seguridad. 
-Key Vault should have soft delete 
Propósito: evitar eliminación. Fin: seguridad.  
Despliegue: 
1.	Accedes al management group 
2.	Settings > Policies 
3.	Add New Policy 
4.	Creación de Azure Key Vault asociado al RG  
7.3. RG Platform Identity 
Este RG queda vacío en el despliegue inicial. 
Recursos dentro 
•	Managed Identities (cuando se necesiten) 
Políticas específicas 
Ninguna por ahora.  
Despliegue 
1.	Crear RG 
2.	Dejarlo preparado 
7.4. RG Platform Networking 
Recursos dentro 
•	VNET Hub (10.0.0.0/24) 
•	Subredes 
•	NSG 
•	Route Tables 
•	DNS Private Zones 
Política específica del RG 
-Subnets should have a Network Security Group 
Propósito: evitar subredes sin protección. 
Fin: seguridad básica.  
Orden de despliegue 
1.	Crear RG 
2.	Crear VNET Hub + subredes 
3.	Crear NSG 
4.	Crear DNS Private Zones 
5.	Asignar política de NSG obligatorio 
7.5. RG Platform Management  
Recursos dentro 
•	Log Analytics Workspace 
•	Action Groups 
•	Alert Rules 
•	(Opcional) Automation Account 
•	Dashboards / Workbooks  
Políticas específicas del RG (opcionales) 
-Audit resources without required tags 
Propósito: orden. 
Fin: gobernanza.  
Orden de despliegue 
1.	Crear RG 
2.	Crear LAW  
7.6. RG LZ Dev / Test / Prod / Sandbox 
Recursos dentro (inicialmente) 
•	VNET Spoke 
•	Subnet 
•	Peering con el Hub 
Política específica por entorno 
-Require tag and its value (environment) 
Propósito: identificar recursos por entorno. Fin: orden y gobernanza. 
-Allowed virtual machine SKUs 
Propósito: Permitir solo ciertos tipos de SKUs. Fin: control 
Dev/Test: 
•	B1s 
•	B2s 
Prod: 
•	D Series 
•	E Series pequeñas 
•	F Series pequeñas  
  
Direccionamiento recomendado: 
Perfecto para una LZ personal, profesional y escalable. 
VNET Hub → 10.0.0.0/24 
Subredes: 
•	AzureFirewallSubnet → 10.0.0.0/26 
•	AzureBastionSubnet → 10.0.0.64/27 
•	GatewaySubnet → 10.0.0.96/27 
•	SharedServicesSubnet → 10.0.0.128/25 
VNET Spoke Dev → 10.1.0.0/24 
VNET Spoke Test → 10.2.0.0/24 
VNET Spoke Prod → 10.3.0.0/24 
VNET Spoke Sandbox → 10.4.0.0/24 