RSpec.describe Interactify::UniqueKlassName do
  describe ".for" do
    it "generates a unique class name" do
      first_name = described_class.for(SpecSupport, 'Whatever')
      expect(first_name).to match(/Whatever\d+/)
      SpecSupport.const_set(first_name, Class.new)

      second_name = described_class.for(SpecSupport, 'Whatever')
      expect(second_name).to match(/Whatever\d+/)
      expect(first_name).not_to eq(second_name)
    end
  end

  describe ".generate_unique_id" do
    it "generates a random number within the specified range" do
      unique_id = described_class.generate_unique_id

      expect(unique_id).to be >= 0
      expect(unique_id).to be < 10_000
    end
  end
end
