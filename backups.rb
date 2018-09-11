require 'json'
require 'csv'
require_relative './testrail'

# Add suite ids to backup here
Suite_ids= ['3557', '4892', '4401']


# API variables.
TR_USERNAME=ENV['TR_USERNAME']
TR_PASSWORD=ENV['TR_PASSWORD']
BASE_URL='https://intouch.testrail.com'

puts ENV['TR_USERNAME']

Suite_ids.each do |suite_id|

# Get sections and cases and parse them
client = TestRail::APIClient.new(BASE_URL)
client.user = TR_USERNAME
client.password = TR_PASSWORD
tr_suite = client.send_get("get_suite/#{suite_id}").to_json
suiteParsed = JSON.parse(tr_suite)
puts "Backing up #{suiteParsed['name']}"
tr_sections = client.send_get("get_sections/#{suiteParsed['project_id']}&suite_id=#{suite_id}").to_json
tr_cases = client.send_get("get_cases/#{suiteParsed['project_id']}&suite_id=#{suite_id}").to_json
sectionsParsed = JSON.parse(tr_sections)
casesParsed = JSON.parse(tr_cases)



# Create a new hash for easier merging later
hierarchy = Hash.new
sectionsParsed.each do |section|
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
casesParsed.each do |trCase|
        trCase.merge!(hierarchy[trCase["section_id"]])
end


# Convert to csv and save
datetime = Time.new.strftime("%Y-%m-%d %H-%M-%S")
Dir.mkdir("Results") unless File.exists?("Results")
CSV.open("Results/#{suiteParsed['name']} #{datetime}.csv", 'w') do |csv|
    headers = casesParsed.first.keys
    csv << headers
    casesParsed.each do |item|
        values = item.values
        printable_values = Array.new
        values.each do |value|
            printable_values << value.to_s.gsub(/\[|\]/,'').gsub(/"/,'\'')
        end
    csv << printable_values
    end
end
end
puts "Done!"