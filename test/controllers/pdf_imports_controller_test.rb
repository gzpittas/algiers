require "test_helper"

class PdfImportsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get pdf_imports_new_url
    assert_response :success
  end

  test "should get create" do
    get pdf_imports_create_url
    assert_response :success
  end
end
