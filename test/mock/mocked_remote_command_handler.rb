# To change this template, choose Tools | Templates
# and open the template in the editor.

class MockedRemoteCommandHandler
  attr_accessor :drive_mounted

  def initialize
    @connected = false
    @drive_mounted = false
  end

  def connect(ip, key)
    puts "mocked_ssh_api: connected to ip=#{ip} keys=#{key}"
    @connected = true
  end

  def drive_mounted?(path)
    test_connected()
    @drive_mounted
  end

  def drive_mounted_as?(device, path)
    test_connected()
    @drive_mounted
  end

  def disconnect
    test_connected()
    puts "mocked_ssh_api: disconnected"
  end

  def install(software_package)
    test_connected()
    puts "mocked_ssh_api: install #{software_package}"
  end

  def tools_installed?(software_package)
    test_connected()
    puts "mocked_ssh_api: check_install #{software_package}"
    true
  end

  def encrypt_storage(name, password, mount_point, path)
    test_connected()
    puts "mocked_ssh_api: encrypt_storage #{name} #{password},#{mount_point},#{path}"
    #Create a dm-encrypted partition on the EBS volume:
    "sudo cryptsetup create dm-atrust /dev/sdd"
      #=> issue? you will be prompted for a passphrase – user a long, complex one – you won’t have to type it by hand anyway)
    #Create a new LVM PV (physical volume) on the encrypted partition:
    "sudo pvcreate /dev/mapper/dm-atrust"
    #Create a new LVM VG (volume group) on the LVM PV:
    "sudo vgcreate vg-atrust /dev/mapper/dm-atrust"
    #Create a new LVM LV (logical volume) on the LVM VG:
    "sudo lvcreate -n lv-atrust -L2G vg-atrust"
    #Create a new filesystem on the LVM LV:
    "sudo mkfs -t xfs /dev/vg-atrust/lv-atrust" #(you can use any filesystem, I just like XFS)
    #Mount and test our your encrypted volume:
    "sudo mount /dev/vg-atrust/lv-atrust /atrust"
    @drive_mounted = true
  end

  def storage_encrypted?(password, device, path)
    test_connected()
    puts "mocked_ssh_api: test_storage_encryption #{password},#{device},#{path}"
  end

  def activate_encrypted_volume(device, path)
    test_connected()
    puts "mocked_ssh_api: activate_encrypted_volume #{device},#{path}"
  end

  def undo_encryption(name, path)
    test_connected()
    puts "mocked_ssh_api: undo_encryption #{name} #{path}"
  end

  def umount(path)
    test_connected()
    puts "mocked_ssh_api: umount #{path}"
    @drive_mounted = false
  end

  private

  def test_connected()
    if !@connected
      raise Exception.new("not connected")
    end
  end


end
