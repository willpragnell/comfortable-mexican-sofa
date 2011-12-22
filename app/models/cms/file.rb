require 'dragonfly/rails/images'

class Cms::File < ActiveRecord::Base
  
  IMAGE_MIMETYPES = %w(gif jpeg pjpeg png svg+xml tiff).collect{|subtype| "image/#{subtype}"}
  
  ComfortableMexicanSofa.establish_connection(self)
    
  self.table_name = 'cms_files'
  
  cms_is_categorized
  
  attr_accessor :dimensions
  
  # -- AR Extensions --------------------------------------------------------
  image_accessor :file
  
  # -- Relationships --------------------------------------------------------
  belongs_to :site
  belongs_to :block
  
  # -- Validations ----------------------------------------------------------
  validates :site_id, :presence => true
  
  # -- Callbacks ------------------------------------------------------------
  before_save   :assign_label
  before_create :assign_position
  after_save    :reload_page_cache
  after_destroy :reload_page_cache
  
  # -- Scopes ---------------------------------------------------------------
  scope :images,      where(:file_mime_type => IMAGE_MIMETYPES)
  scope :not_images,  where('file_mime_type NOT IN (?)', IMAGE_MIMETYPES)
  
  # -- Instance Methods -----------------------------------------------------
  def is_image?
    IMAGE_MIMETYPES.include?(file_mime_type)
  end
  
protected
  
  def assign_label
    self.label = self.label.blank?? self.file_name.gsub(/\.[^\.]*?$/, '').titleize : self.label
  end
  
  def assign_position
    max = Cms::File.maximum(:position)
    self.position = max ? max + 1 : 0
  end
  
  # FIX: Terrible, but no way of creating cached page content overwise
  def reload_page_cache
    return unless self.block
    p = self.block.page
    Cms::Page.where(:id => p.id).update_all(:content => p.content(true))
  end
  
end
