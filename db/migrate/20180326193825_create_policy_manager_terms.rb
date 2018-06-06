class CreatePolicyManagerTerms < ActiveRecord::Migration
  def change
    create_table :policy_manager_terms do |t|
      t.text :description
      t.string :rule
      t.string :state
      t.datetime :accepted_at
      t.datetime :rejected_at
      t.timestamps
    end
  end
end
