require 'json'
require 'csv'
require_relative './testrail'

# API variables.

PROJECT_ID='18'
SUITE_ID='4401'
TR_USERNAME='aguerra@intouchhealth.com'
TR_PASSWORD='Afg*101295.'
BASE_URL='https://intouch.testrail.com'



# Get sections and cases and parse them
client = TestRail::APIClient.new(BASE_URL)
client.user = TR_USERNAME
client.password = TR_PASSWORD
tr_sections = client.send_get('get_sections/' + PROJECT_ID + '&suite_id=' + SUITE_ID).to_json
tr_cases = client.send_get('get_cases/' + PROJECT_ID + '&suite_id=' + SUITE_ID).to_json
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

directory_name = "Results"
Dir.mkdir(directory_name) unless File.exists?(directory_name)

CSV.open('Results/result1.csv', 'w') do |csv|
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