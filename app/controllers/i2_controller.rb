########################################################################
# File::    i2_controller.rb
# (C)::     Hipposoft 2011-2024
#
# Purpose:: Support common I2 paths within Instiki for legacy links.
# ----------------------------------------------------------------------
#           16-Mar-2011 (ADH): Created.
#           05-Jul-2024 (ADH): Overdue update to modern Hash syntax.
########################################################################

class I2Controller < ApplicationController
  def pages
    redirect_to(
      controller: 'wiki',
      action:     'show',
      id:         params[:id].gsub('+', ' ')
    )
  end
end
