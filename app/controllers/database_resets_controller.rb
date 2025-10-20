# app/controllers/database_resets_controller.rb
class DatabaseResetsController < ApplicationController
  before_action :authenticate_user!
  before_action :check_environment!
  
  def create
    begin
      # Disconnect all active connections first
      ActiveRecord::Base.connection.disconnect!
      
      # Run the database reset commands
      result = system('rails db:drop db:create db:migrate')
      
      # Reconnect
      ActiveRecord::Base.establish_connection
      
      if result
        # Create a default user for development
        User.create!(
          email: 'dev@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        )
        
        redirect_to pdf_imports_path, notice: "Database successfully reset! User created: dev@example.com / password123"
      else
        redirect_to pdf_imports_path, alert: "Database reset failed. Check server logs."
      end
    rescue => e
      # Make sure we reconnect even if there's an error
      ActiveRecord::Base.establish_connection rescue nil
      redirect_to pdf_imports_path, alert: "Error resetting database: #{e.message}"
    end
  end
  
  private
  
  def check_environment!
    unless Rails.env.development?
      redirect_to root_path, alert: "Database reset is only allowed in development environment!"
    end
  end
end