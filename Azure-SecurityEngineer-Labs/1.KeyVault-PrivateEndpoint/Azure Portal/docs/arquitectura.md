En este proyecto voy a mostrar cómo una máquina virtual en Azure puede acceder de forma segura a un secreto almacenado en Key Vault sin usar credenciales.
Usaremos identidad gestionada, permisos RBAC y un Private Endpoint para que todo el tráfico vaya por la red privada, sin exponer el Key Vault a Internet.

El objetivo es entender cómo se combinan identidad, permisos y red para proteger secretos de forma moderna y totalmente segura.

1. Crear el Resource Group
Agrupa todos los recursos del laboratorio en una misma región para evitar problemas de red.
    • Portal → Resource groups → Create
    • Name: rg-security-lab
    • Region: Spain Central

2.	Crear el Key Vault
El Key Vault será el almacén seguro donde guardaremos el secreto.
    • Portal → Key Vaults → Create
    • Name: kv-security-lab
    • Region: misma que el RG
    • Pricing tier: Standard
    • Access configuration: Role-based access control (RBAC)
    • Networking: Public access: Enabled (solo temporal)

3.	Crear un secreto en el Key Vault
Asignación de roles previos a ti como Admin para poder trabajar con Key Vault:
    • Key Vault Secrets Officer (crear secretos, actualizar secretos, borrar secretos, gestionar versiones)
    • Key Vault Secrets User (leer el valor del secreto y listar secretos)

Creamos un valor sensible que la VM necesitará obtener.
    • Key Vault → Secrets → Generate/Import
    • Name: test-password
    • Value: SuperSecret123!

4.	Crear la VM con Managed Identity
La VM usará su identidad administrada para autenticarse sin contraseñas.
    • Portal → Virtual Machines → Create
    • Name: vm01
    • Size: B1s
    • OS: Windows Server 2022 DataCenter
    • Networking: VNet nueva
    • vm01-vnet: 10.0.0.0/24 -> 10.0.0.1 - 10.0.0.255 (Red Virtual)
    • vm-snet: 10.0.0.0/26 -> 10.0.0.1 – 10.0.0.63 (Subred Virtual)
    • pe-snet: 10.0.0.64/26 -> 10.0.0.65 – 10.0.0.127 (Subred Virtual)

    •	Identity → System-assigned: ON

5.	Asignar permisos RBAC a la VM
La Managed Identity se autentica, pero necesita permisos para leer secretos.
    • Key Vault → Access control (IAM) → Add role assignment
    • Role: Key Vault Secrets User
    • Assign to: Managed Identity de la VM

6.	Probar acceso desde la VM (Prueba 1)
Antes de lanzar el script por primera vez:
    • Install-Module -Name Az.KeyVault -AllowClobber -Force

La vm no tiene credenciales. Con este comando usa la identidad administrada para solicitar un token a Entra ID
    • Connect-AzAccount -Identity

Copiamos el script "get_kvsecret.ps1" en la VM y lo ejecutamos.
Veremos que el almacen Key Vault nos da el valor del secreto "test-password"

7.	Cerrar el acceso público del Key Vault
Bloqueamos el acceso desde Internet para endurecer la superficie de ataque.
    • Key Vault → Networking → Firewalls and virtual networks
    • Public access: Disabled
    • Trusted services: opcional

8.	Probar acceso sin Private Endpoint (Prueba 2)
La VM ya no puede llegar al Key Vault aunque tenga permisos.
    • Ejecutar el mismo script que antes
    • Resultado: Error de red / Forbidden

Aquí confirmaremos que no tenemos acceso al secreto y que es necesario crear un Private Endpoint.

9.	Crear el Private Endpoint
Creamos una ruta privada para acceder al Key Vault sin pasar por Internet.
    • Portal → Private Endpoint → Create
    • Name: pe-kv
    • Resource: tu Key Vault
    • VNet: la única que tenemos
    • Subnet: preferiblemente dedicada llamada "pe-snet" (10.0.0.64/26)
    • Se crea automáticamente:
        o NIC privada
        o Private DNS Zone: privatelink.vaultcore.azure.net
        o Registro A para el Key Vault

10. Probar acceso con Private Endpoint (Prueba 3)
La VM vuelve a acceder al secreto, ahora de forma segura.
    • Ejecutar el mismo script
    • Resultado: Funciona


Flujo:
1.	La VM ejecuta el script y necesita resolver el FQDN del Key Vault.
2.	La Private DNS Zone devuelve la IP privada del Private Endpoint.
3.	La VM se conecta a esa IP privada (la NIC del PE).
4.	El Private Endpoint recibe la petición y la envía al Key Vault por dentro de Azure.
5.	El Key Vault responde al PE, y el PE responde a la VM.
