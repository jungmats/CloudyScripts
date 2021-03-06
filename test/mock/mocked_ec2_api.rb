class MockedEc2Api
  attr_accessor :volumes, :next_volume_id, :fail

  def initialize
    @volumes = []
    @instances = []
    @fail = false
    @next_volume_id = nil
  end

  def create_snapshot(volume_id)
    cause_failure()    
    puts("MockedEc2API: create snapshot for #{volume_id}")
    snap = "snap_#{Time.now.to_i.to_s}"
    {"volumeId"=>"#{volume_id}", "snapshotId"=>"#{snap}", "requestId"=>"dummy-request",
      "progress"=>nil, "startTime"=>"2009-11-11T17:06:14.000Z",
      "status"=>"pending", "xmlns"=>"http://ec2.amazonaws.com/doc/2008-12-01/"}
  end

  def delete_snapshot(options = {})
    res = {}
    res['return'] = "true"
    res['requestId'] = "dummy-request-id"
    res['xmlns'] = "http://ec2.amazonaws.com/doc/2008-12-01/"
    res
  end

  def describe_keypairs(keynames = nil)
    cause_failure()    
    all_key_names = []
    if keynames == nil
      keynames = []
      @instances.each() {|i|
        all_key_names << i[:key_name]
      }
    else
      keynames = keynames[:key_name]
      @instances.each() {|i|
        if i[:key_name] == keynames[0]
          all_key_names << i[:key_name]
        end
      }
    end
    res = {}
    res['keySet'] = {}
    res['keySet']['item'] = []
    res['keySet']['requestId'] = "dummy-request-id"
    res['keySet']['xmlns'] = "http://ec2.amazonaws.com/doc/2008-12-01/"
    all_key_names.each() {|kn|
      key = {}
      key['keyName'] = kn
      key['keyFingerprint'] = "00:11:22:33:44:55:66:77:88:99:00:11:22:33:44:55:66:77:88:99"
      res['keySet']['item'] << key
    }
    res
  end

  def describe_security_groups(*security_group_names)
    cause_failure()    
    groups = identify_security_groups()
    puts "mocked_ec2_api.describe_security_groups identified #{groups.inspect}"
    res = transform_secgroups(groups)
    res
  end

  def identify_security_groups
    sec_groups = []
    @instances.each() {|i|
      i.groups.each() {|group|
        if !sec_groups.include?(group)
          sec_groups << group
        end
      }
    }
    sec_groups
  end

  def transform_secgroups(secgroups)
    ret = {}
    ret['securityGroupInfo'] = {}
    ret['securityGroupInfo']['item'] = []
    secgroups.each() {|sg|
      group = {}
      group['groupName'] = sg
      ret['securityGroupInfo']['item'] << group
      #TODO: missing stuff ownerId, ipPermissions, etc
    }
    ret
  end

  # Expects eiter an empty value or an hash {:volume_id => [bla]}
  def describe_volumes(volume_ids = nil)
    if volume_ids != nil
      #needed to adapt to the API
      volume_ids = volume_ids[:volume_id]
    else
      volume_ids = []
    end
    cause_failure()
    puts "params = #{volume_ids.inspect} number=#{volume_ids.length}"
    if volume_ids.length == 0
      v = @volumes
    else
      v = @volumes.select() {|i|
        puts "compare '#{i[:volume_id].inspect}' with '#{volume_ids[0].inspect}' =>#{(i[:volume_id] == volume_ids[0])}"
        (i[:volume_id] == volume_ids[0])
      }
    end
    puts "all volumes = #{@volumes.inspect} v=#{v.inspect}"
    transform_volumes(v)
  end

  def create_volume(timezone)
    cause_failure()
    puts "GOING TO CREATE VOLUME!"
    volume = {}
    vid = "vol-#{Time.now.to_i.to_s}"
    if next_volume_id() != nil
      vid = next_volume_id()
    end
    @next_volume_id = nil
    volume[:volume_id] = vid
    puts "create volume with id = #{volume[:volume_id]}"
    volume[:availability_zone] = timezone
    volume[:create_time] = Time.now
    volume[:volume_id]
    volume[:attachments] = []    
    @volumes << volume
    {'volumeId'=> vid}
  end

  # Expects either no params or an hash {:instance_id => [ids]}
  def describe_instances(instance_ids = nil)
    if instance_ids != nil
      #needed to adapt to the API
      instance_ids = instance_ids[:instance_id]
    else
      instance_ids = []
    end
    puts "instance_ids = #{instance_ids.inspect} number=#{instance_ids.length}"
    if instance_ids == nil || instance_ids.length == 0
      return transform_instances(@instances)
    else
      return transform_instances(@instances.select() {|i|
        instance_ids.include?(i[:instance_id])
      })
    end
  end

  def transform_instances(instances)
    puts "found #{instances.size} instances to transform"
    ret = {}
    ret['requestId'] = "request-id-dummy"
    ret['reservationSet'] = {}
    items = []
    ret['reservationSet']['item'] = items
    instances.each() {|i|
      puts "start transforming #{i.inspect}"
      item = {}
      groupSet = []
      instancesSet = {}
      item['reservationId'] = "r-"+i[:instance_id]
      item['requesterId'] = 'dummy-requester-id'
      item['groupSet'] = {}
      item['groupSet']['item'] = groupSet
      item['instancesSet'] = instancesSet
      instancesSet['item'] = []
      instanceInfos = {}
      instancesSet['item'] << instanceInfos
      instanceInfos['keyName'] = i[:key_name]
      instanceInfos['ramdiskId'] = 'dummy-ramdisk-id'
      instanceInfos['productCodes'] = nil #TODO: must be a set
      instanceInfos['kernelId'] = 'aki-'+i[:instance_id]
      instanceInfos['launchTime'] = DateTime.new
      instanceInfos['amiLaunchIndex'] = 0 #TODO: count instances?
      instanceInfos['imageId'] = i[:image_id]
      instanceInfos['instanceType'] = "m1.small" #TODO: must be configurable
      instanceInfos['reason'] = nil #TODO: have a closer look at this
      instanceInfos['placement'] = {}
      instanceInfos['placement']['availabilityZone'] = i[:availability_zone]
      instanceInfos['instanceId'] = i[:instance_id]
      instanceInfos['privateDnsName'] = i[:private_dns_name]
      instanceInfos['dnsName'] = i[:dns_name]
      instanceInfos['instanceState'] = {}
      instanceInfos['instanceState']['name'] = i[:instance_state]
      instanceInfos['instanceState']['code'] = "11" #TODO: get those codes
      instanceInfos['ownerId'] = "owner-dummy-id"
      puts "mocked_ec2_api is going to add #{i[:groups].size} groups"
      i[:groups].each() {|sg|
        elem = {}
        elem['groupId'] = sg
        groupSet << elem
      }
      puts "going to add item = #{item.inspect}"
      items << item
    }
    return ret
  end

  def transform_volumes(volumes)
    puts "found #{volumes.size} volumes to transform"
    ret = {}
    ret['volumeSet'] = {}
    items = []
    ret['volumeSet']['item'] = items
    volumes.each() {|v|
      puts "start transforming #{v.inspect}"
      item = {}
      attachmentSet = {}
      item['attachmentSet'] = attachmentSet #TODO: attachments not yet possible
      if v[:attachments].size > 0
        puts "#{item['attachmentSet']}"
        item['attachmentSet']['item'] = []
        v[:attachments].each() {|a|
          puts "attachment found: #{a.inspect}"
          attachments = {}
          attachments['device'] = a[:device]
          attachments['volumeId'] = v[:volume_id]
          attachments['instanceId'] = a[:instance_id]
          attachments['status'] = "attached"
          attachments['attachTime'] = DateTime.now
          item['attachmentSet']['item'] << attachments
        }
      end
      item['createTime'] = v[:create_time]
      item['size'] = 1 #TODO make configurable?
      item['volumeId'] = v[:volume_id]
      item['snapshotId'] = nil #TODO: make configurable?
      item['status'] = 'availabe' #TODO: nowhere
      item['availabilityZone'] = v[:availability_zone]
      items << item
    }
    return ret
  end

  def attach_volume(options)
    cause_failure()
    volume_id = options[:volume_id]
    instance_id = options[:instance_id]
    device = options[:device]
    puts "attach vol #{volume_id} to instance #{instance_id}"
    volume = get_volume(volume_id)
    puts "volume = #{volume.inspect}"
    instance = get_instance(instance_id)
    puts "instance = #{instance.inspect}"
    if volume == nil
      raise Exception.new("volume #{volume_id} does not exist")
    end
    if instance == nil
      raise Exception.new("instance #{instance_id} does not exist")      
    end
    att = {}
    att[:instance_id] = instance_id
    att[:device] = device
    puts "add #{att.inspect} to attachments = #{volume[:attachments].inspect}"
    volume[:attachments] << att
    puts "after attaching: #{@volumes.inspect}"
  end

  def detach_volume(options)
    cause_failure()
    volume = get_volume(options[:volume_id])
    puts "volume = #{volume.inspect}"
    instance = get_instance(options[:instance_id])
    puts "instance = #{instance.inspect}"
    if volume == nil
      raise Exception.new("volume #{options[:volume_id]} does not exist")
    end
    if instance == nil
      raise Exception.new("instance #{options[:instance_id]} does not exist")
    end
    att = volume[:attachments]
    puts "attachments = #{att.inspect}"
    count = 0
    to_remove = -1
    att.each() {|a|
      if a[:instance_id] == options[:instance_id]
        puts "going to remove #{a.inspect}"
        to_remove = count
        break
      end
      count += 1
    }
    if to_remove != -1
      volume[:attachments].delete_at(to_remove)
    end
    puts "after detaching: #{@volumes.inspect}"
  end

  def delete_volume(options)
    volume_id = options[:volume_id]
    remove_dummy_volume(volume_id)
  end

  #the following methods are additional helper methods

  def create_dummy_volume(id, timezone)
    self.next_volume_id = id
    return create_volume(timezone)
  end
  
  def remove_dummy_volume(id)
    @volumes = @volumes.select() {|v|
      v[:volume_id] != id
    }
  end

  def get_volume(id)
    @volumes.each() {|v|
      if v[:volume_id] == id
        puts "get_volume: #{v.inspect}"        
        return v
      end
    }
    puts "no volume found"
    return nil
  end
  
  def get_instance(id)
    @instances.each() {|i|
      if i[:instance_id] == id
        puts "get_instance: #{i.inspect}"
        return i
      end
    }
    puts "no instance found"
    return nil
  end

  #result of describe_instances:
  #{"requestId"=>"9286df07-8937-4233-954a-e26b13780c2f", "reservationSet"=>{"item"=>[{"reservationId"=>"r-66d2260e", "requesterId"=>"058890971305", "groupSet"=>{"item"=>[{"groupId"=>"Rails Starter"}]}, "instancesSet"=>{"item"=>[{"keyName"=>"jungmats", "ramdiskId"=>"ari-dbc121b2", "productCodes"=>nil, "kernelId"=>"aki-f5c1219c", "launchTime"=>"2009-10-22T14:26:12.000Z", "amiLaunchIndex"=>"0", "imageId"=>"ami-22b0534b", "instanceType"=>"m1.small", "reason"=>nil, "placement"=>{"availabilityZone"=>"us-east-1d"}, "instanceId"=>"i-0071c968", "privateDnsName"=>"ip-10-244-159-112.ec2.internal", "dnsName"=>"ec2-174-129-149-1.compute-1.amazonaws.com", "instanceState"=>{"name"=>"running", "code"=>"16"}}]}, "ownerId"=>"945722764978"}, {"reservationId"=>"r-0e13e166", "requesterId"=>"058890971305", "groupSet"=>{"item"=>[{"groupId"=>"EU"}, {"groupId"=>"cloudkick"}]}, "instancesSet"=>{"item"=>[{"keyName"=>"jungmats", "ramdiskId"=>"ari-dbc121b2", "productCodes"=>nil, "kernelId"=>"aki-f5c1219c", "launchTime"=>"2009-10-27T18:05:03.000Z", "amiLaunchIndex"=>"0", "imageId"=>"ami-2cb05345", "instanceType"=>"m1.small", "reason"=>nil, "placement"=>{"availabilityZone"=>"us-east-1d"}, "instanceId"=>"i-16e8687e", "privateDnsName"=>"ip-10-245-206-177.ec2.internal", "dnsName"=>"ec2-67-202-11-96.compute-1.amazonaws.com", "instanceState"=>{"name"=>"running", "code"=>"16"}}]}, "ownerId"=>"945722764978"}]}, "xmlns"=>"http://ec2.amazonaws.com/doc/2008-12-01/"}


  def create_instance(instance_id)
    instance = {}
    instance[:instance_id] = instance_id
    instance[:image_id] = "dummy image"
    #TODO
    @instances << instance
    instance
  end
  
  def create_dummy_instance(instance_id, image_id, instance_state, private_dns_name, dns_name, key_name, groups = [])
    instance = {}
    instance[:instance_id] = instance_id
    instance[:image_id] = image_id
    instance[:instance_state] = instance_state
    instance[:private_dns_name] = private_dns_name
    instance[:dns_name] = dns_name
    instance[:key_name] = key_name
    instance[:groups] = groups
    instance[:availability_zone] = "us-east-1a" #TODO: make configurable
    #TODO
    @instances << instance
    instance
  end  
    
  private
  
  def cause_failure()
    if @fail
      puts "mocked_ec2 API is in failure mode"
      raise Exception.new("mocked_ec2 API is in failure mode")
    end
  end
  
end