class DropRevisionIpAddressColumn < ActiveRecord::Migration[8.0]
  def up
    remove_column :revisions, :ip
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
