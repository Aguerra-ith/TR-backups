require 'json'
require 'csv'
require_relative './testrail'

# Set required variables and open files
sectionsFile = open("tr_sections.json")
casesFile = open("tr_cases.json")
resultFile = File.new("json/result.json", "w")
sectionsParsed = JSON.parse(sectionsFile.read)
casesParsed = JSON.parse(casesFile.read)
hierarchy = Hash.new
PROJECT_ID='18'
SUITE_ID='4401'

# API variables.
TR_USERNAME='aguerra@intouchhealth.com'
TR_PASSWORD='Afg*101295.'
BASE_URL='https://intouch.testrail.com'




client = TestRail::APIClient.new(BASE_URL)
client.user = TR_USERNAME
client.password = TR_PASSWORD
c = client.send_get('get_sections/' + PROJECT_ID + '&suite_id=' + SUITE_ID)
puts c 




# Create a new hash for easier merging later
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

# Save results as json
resultFile.write(casesParsed.to_json)


# Convert to csv and save
CSV.open('csv/test.csv', 'w') do |csv|
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