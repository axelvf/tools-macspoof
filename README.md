# Mac Address spoof
## Usage

This script must be run with super-user privileges.

`macspoof.sh [-i <wifi-interface>] [-m <mac-address>]`

### Options

   -h      Show this message
   
   -i      Wifi interface name (default is en0)
   
   -m      MAC Address. If empty, a random address is used
   
   -v      Verbose

### Examples

Change with generic mac:

`sudo ./macspoof.sh -i en0`

Change with specific mac:

`sudo ./macspoof.sh -i en0 -m a0:99:9b:0c:e0:77`
