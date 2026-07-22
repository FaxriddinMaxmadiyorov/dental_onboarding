# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

%w[English Dutch German French Spanish Russian Uzbek Turkish Arabic].each do |name|
  Language.find_or_create_by!(name: name)
end

skills_data = {
  "dentist" => %w[Endodontics Restorative\ dentistry Pediatric\ dentistry Surgery Aligners],
  "dental_hygienist" => %w[Periodontology Prevention Scaling Patient\ education],
  "dental_assistant" => %w[Chairside\ assistance Sterilization Orthodontics Prevention],
  "front_office" => %w[Planning Phone\ handling Invoicing Patient\ communication],
  "practice_manager" => %w[Team\ management Scheduling HR Practice\ operations],
  "dental_technician" => %w[Prosthetics CAD/CAM Crown\ and\ bridge\ work]
}

skills_data.each do |group, names|
  names.each { |name| Skill.find_or_create_by!(name: name, function_group: group) }
end