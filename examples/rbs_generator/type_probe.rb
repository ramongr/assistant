# frozen_string_literal: true

require_relative 'create_user'

service = RbsGeneratorExample::CreateUser.new(email: 'ada@example.com', name: 'Ada', role: :admin)

service.email.upcase
service.name.length
service.role&.to_s
