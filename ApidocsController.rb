class ApidocsController < ActionController::Base
  include Swagger::Blocks

  swagger_root do
    key :swaggerVersion, '1.2'
    key :apiVersion, '1.0.0'
    info do
      key :title, 'Swagger Sample App'
    end
    api do
      key :path, '/pets'
      key :description, 'Operations about pets'
    end
  end

  # A list of all classes that have swagger_* declarations.
  SWAGGERED_CLASSES = [
    PetsController,
    Pets,
    self,
  ].freeze

  def index
    render json: Swagger::Blocks.build_root_json(SWAGGERED_CLASSES)
  end

  def show
    render json: Swagger::Blocks.build_api_json(params[:id], SWAGGERED_CLASSES)
  end
end