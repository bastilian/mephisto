#encoding: UTF-8
class AssetsController < ApplicationController

  caches_page_with_references :show
  def show
    file         = Pathname.new([params[:path], params[:ext]] * '.')
    content_type = site.resources.content_type(file)
    resource     = site.resources[file.to_s]

    if !resource.file?
      show_404
    elsif site.resources.image?(file)
      send_data resource.read.encode!('UTF-8', 'UTF-8', :invalid => :replace), :filename => resource.basename.to_s, :type => content_type, :disposition => 'inline'
    else
      headers['Content-Type'] = content_type
      render :text => resource.read.encode!('UTF-8', 'UTF-8', :invalid => :replace)
    end
  end
end
