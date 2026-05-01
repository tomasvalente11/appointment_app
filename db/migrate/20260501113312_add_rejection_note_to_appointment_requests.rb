class AddRejectionNoteToAppointmentRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :appointment_requests, :rejection_note, :text
  end
end
