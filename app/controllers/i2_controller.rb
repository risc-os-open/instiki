########################################################################
# File::    i2_controller.rb
# (C)::     Hipposoft 2011-2017
#
# Purpose:: Support common I2 paths within Instiki for legacy links.
# ----------------------------------------------------------------------
#           16-Mar-2011 (ADH): Created.
#           15-Jan-2017 (ADH): Imported into new Instiki code for site
#                              rebuild.
########################################################################

class I2Controller < ApplicationController
  def pages
    redirect_to :controller => 'wiki',
                :action     => 'show',
                :id         => params[:id].gsub('+', ' ')
  end
end
