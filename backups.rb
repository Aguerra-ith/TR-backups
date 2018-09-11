require 'json'
require 'csv'
require_relative './testrail'

# Add project ids to backup here
Projects = [18, 20, 13, 4]


# API variables.
TR_USERNAME=ENV['TR_USERNAME']
TR_PASSWORD=ENV['TR_PASSWORD']
BASE_URL='https://intouch.testrail.com'

client = TestRail::APIClient.new(BASE_URL)
client.user = TR_USERNAME
client.password = TR_PASSWORD
Dir.mkdir("VE-Backups") unless File.exists?("VE-Backups")

puts "Starting..."


Projects.each do |tr_project_id|
  tr_project_suites = JSON.parse(client.send_get("get_suites/#{tr_project_id}").to_json)
  tr_project_name = JSON.parse(client.send_get("get_project/#{tr_project_id}").to_json)['name']
  puts ">>>>>>>>>> #{tr_project_name} <<<<<<<<<<"
  Dir.mkdir("VE-Backups/#{tr_project_name}") unless File.exists?("VE-Backups/#{tr_project_name}")


  # Create array containing Suite IDs
  tr_project_suites.each do |suite|
    puts "Backing up #{suite['name']}"
    tr_sections = JSON.parse(client.send_get("get_sections/#{suite['project_id']}&suite_id=#{suite['id']}").to_json)
    tr_cases = JSON.parse(client.send_get("get_cases/#{suite['project_id']}&suite_id=#{suite['id']}").to_json)



    # Create a new hash for easier merging later
    hierarchy = Hash.new
    tr_sections.each do |section|
      section.each do |key, value|
        hierarchy.merge!({section["id"] => {"section_hierarchy" => section["name"], "section_parent_id" => section["parent_id"], "section_description" => section["description"]}})
      end
    end


    # Construct hierarchy
    hierarchy.each do |id, nameAndParent|
      hierarchy.each do |id2, nameAndParent2|
        if nameAndParent["section_parent_id"] != nil && nameAndParent["section_parent_id"] == id2
          nameAndParent["section_hierarchy"] = nameAndParent2["section_hierarchy"] + " > " + nameAndParent["section_hierarchy"]
        end
      end
    end

    # Add section hierarchy to the cases
    tr_cases.each do |trCase|
      trCase.merge!(hierarchy[trCase["section_id"]])
    end


    # Convert to csv and save
    datetime = Time.new.strftime("%Y-%m-%d %H-%M-%S")
    CSV.open("VE-Backups/#{tr_project_name}/#{suite['name']} #{datetime}.csv", 'w') do |csv|
      headers = tr_cases.first.keys
      csv << headers
      tr_cases.each do |item|
        values = item.values
        printable_values = Array.new
        values.each do |value|
          printable_values << value.to_s.gsub(/\[|\]/,'').gsub(/"/,'\'')
        end
        csv << printable_values
      end
    end
  end
end


puts ">>>>>>>>>> Done! Thanks for backing up! <<<<<<<<<<"
