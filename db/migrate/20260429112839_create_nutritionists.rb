class CreateNutritionists < ActiveRecord::Migration[8.1]
  def change
    create_table :nutritionists do |t|
      t.string :name, null: false
      t.text :bio
      t.string :license_number
      t.string :avatar_url

      t.timestamps
    end
  end
end
