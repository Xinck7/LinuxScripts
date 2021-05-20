#Centos 6.9
yum update
reboot
yum groupinstall -y gnome desktop
yum install -y vnc-server*
yum install -y gcc
yum install -y kernel-devel
vim /etc/sysconfig/vncservers

 VNCSERVERS="2:root"                                                                 
 VNCSERVERARGS[2]="-geometry 1280x720"                                               
:wq!
vncpasswd

#set password for the 'root' account for vnc

#If the kernels aren't matching run the following 3 commands

#vi /etc/yum.repos.d/CentOS-Vault.repo
#enabled = 1 on 6.9 base (copy the base and change the 6.8 to 6.9 on both locations for that single entry set)
#yum install kernel-devel-<version>

grubby --update-kernel=ALL --args="rd.driver.blacklist=nouveau nouveau.modeset=0"
mv /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r).img.bak
echo "blacklist nouveau" > /etc/modprobe.d/nouveau-blacklist.conf 
dracut /boot/initramfs-$(uname -r).img $(uname -r)

vi /etc/gdm/custom.conf

# GDM configuration storage                                                          
                                                                                     
[daemon]                                                                             
WaylandEnable=false                                                                  
[security]                                                                           
                                                                                     
[xdmcp]                                                                              
                                                                                     
[greeter]                                                                            
                                                                                     
[chooser]                                                                            
                                                                                     
[debug]                                                                              
:wq!



#Build the driver #Warning if you didn't blacklist nouveau you and run this you have to rebuild the box as far as I know
/opt/video_card_drivers/NVIDIA-Linux-x86_64-384.155-grid.run

answer yes to 32 bit compatibility library and yes nvidia xconfig run


#GRID License
#create from template
#/etc/nvidia/gridd.conf.template

#rename for this file is the path its looking for

cp /etc/nvidia/gridd.conf.template /etc/nvidia/gridd.conf

vi /etc/nvidia/gridd.conf

ServerAddress=<license server>                                            
                                                                                     
ServerPort=7070                                                                      
                                                                                     
FeatureType=1                                                                        
                                                                                     
EnableUI=TRUE                                                                        
                                                                                     
LicenseInterval=1440                                                                 
                                                                                     
LingerInterval=10080
:wq!

chmod 755 /etc/nvidia/gridd.conf

#XORG config 

nvidia-xconfig 

vi /etc/X11/xorg.conf

Section "ServerLayout"                                                               
        Identifier     "X.org Configured"                                            
        Screen      0  "Screen0" 0 0                                                 
        InputDevice    "Mouse0" "CorePointer"                                        
        InputDevice    "Keyboard0" "CoreKeyboard"                                    
EndSection                                                                           
                                                                                     
Section "Files"                                                                      
        ModulePath   "/usr/lib64/xorg/modules"                                       
        FontPath     "catalogue:/etc/X11/fontpath.d"                                 
        FontPath     "built-ins"                                                     
EndSection                                                                           
                                                                                     
Section "Module"                                                                     
        Load  "vnc"                                                                  
        Load  "glx"                                                                  
EndSection                                                                           
                                                                                     
Section "InputDevice"                                                                
        Identifier  "Keyboard0"                                                      
        Driver      "kbd"                                                            
EndSection                                                                           
                                                                                     
Section "InputDevice"                                                                
        Identifier  "Mouse0"                                                         
        Driver      "mouse"                                                          
        Option      "Protocol" "auto"                                                
        Option      "Device" "/dev/input/mice"                                       
        Option      "ZAxisMapping" "4 5 6 7"                                         
EndSection                                                                           
                                                                                     
Section "Monitor"                                                                    
        Identifier   "Monitor0"                                                      
        VendorName   "Monitor Vendor"                                                
        ModelName    "Monitor Model"                                                 
EndSection                                                                           
                                                                                     
                                                                                     
Section "Device"                                                                     
        Identifier  "Device0"                                                        
        Driver      "nvidia"                                                         
        VendorName     "NVIDIA Corporation"                                          
        BusID       "PCI:2:1:0"                                                      
EndSection                                                                           
Section "Screen"                                                                     
        Identifier "Screen0"                                                         
        Device     "Device0"                                                         
        Monitor    "Monitor0"                                                        
        SubSection "Display"                                                         
                Viewport   0 0                                                       
                Depth     1                                                          
        EndSubSection                                                                
        SubSection "Display"                                                         
                Viewport   0 0                                                       
                Depth     4                                                          
        EndSubSection                                                                
        SubSection "Display"                                                         
                Viewport   0 0                                                       
                Depth     8                                                          
        EndSubSection                                                                
        SubSection "Display"                                                         
                Viewport   0 0                                                       
                Depth     15                                                         
        EndSubSection                                                                
        SubSection "Display"                                                         
                Viewport   0 0                                                       
                Depth     16                                                         
        EndSubSection                                                                
        SubSection "Display"                                                         
                Viewport   0 0                                                       
                Depth     24                                                         
        EndSubSection                                                                
EndSection                                                                           
:wq!

#significant section to tie to PCI

#Section "Device"
#    Identifier     "Device0"
#    Driver         "nvidia"
#    VendorName     "NVIDIA Corporation"
#    BusID          "PCI:2:1:0"
#EndSection

#ensure license is pulled with

nvidia-smi

#after verification

#Start vnc to connect

service vncserver start

#note the port :2 = 5902 which would be specified on vnc as "<hostname>::5902"  double colon is significant or "<hostname>:2"

#turn on GUI desktop mode

init 5 

service iptables stop

###############################################
###if you need to fix the 'SIMILAR_TYPE' fix###
###############################################
semanage fcontext -a -t 'console_device_t' 'nvidiactl'
restorecon -v '/dev/nvidiactl'
semanage fcontext -a -t 'console_device_t' 'nvidia0'
restorecon -v '/dev/nvidia0'
###########################################
###########################################
###########################################

#There are a fair amount of adjustments needed for RHEL (go figure)

#Main differences:

have to use X window system and KDE instead of gnome (gnome has a very specific error that isn't fix to this day as far as I know that makes it incompatible with rhel even though its fine on centos)
systemctl/systemd settings are weird and different to get VNC working but the settings aside from that are mostly the same
setting the default to load GUI from boot is a bit easier/ more intuitive even though its more typing it 'just worked' mostly easier on Rhel once you get the commands right
#################

#Rhel 7.5
mkdir /opt/video-card-drivers
yum update
reboot
yum install -y gcc kernel-devel
grubby --update-kernel=ALL --args="rd.driver.blacklist=nouveau nouveau.modeset=0"
mv /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r).img.bak
echo "blacklist nouveau" > /etc/modprobe.d/nouveau-blacklist.conf 
dracut /boot/initramfs-$(uname -r).img $(uname -r)
reboot
yum groupinstall 'X Window System' 'KDE'
yum install -y tigervnc tigervnc-server
cp /usr/lib/systemd/system/vncserver@.service /etc/systemd/system/vncserver@.service
vi /etc/systemd/system/vncserver@.service
add User=vnc and vnc to the <USER> locations
useradd vnc
/opt/video_card_drivers/NVIDIA-Linux-x86_64-384.155-grid.run
vi /etc/gdm/custom.conf
#add
WaylandEnable=false
tail -100 /var/log/messages
#Work through any issues through SElinux blocking crap/relabels



#XORG config
nvidia-xconfig 
#ensure using 
Section "Device"
    Identifier     "Device0"
    Driver         "nvidia"
    VendorName     "NVIDIA Corporation"
    BusID          "PCI:2:1:0"
EndSection
#and loading module "glx" ? rhel didn't need this for licensing atleast or to use kde

#GRID License
#create from template
/etc/nvidia/gridd.conf.template
#rename for this file is the path its looking for
/etc/nvidia/gridd.conf

###########################################