# frozen_string_literal: true

RSpec.describe SoftDelete::SoftDeletable do
  describe '.dependent' do
    subject { described_class.dependent(behavior) }

    let(:behavior) { :ignore }

    context 'when behavior is not :ignore, :default or :soft_delete' do
      let(:behavior) { 'foo' }
      it 'raises ArgumentError' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    it 'returns self' do
      expect(subject).to eq(described_class)
    end
  end

  describe '.not_scoped' do
    with_model :NoteNotScoped, scope: :all do
      table do |t|
        t.string :title
        t.datetime :deleted_at
        t.integer :author_id
      end

      model do
        include SoftDelete::SoftDeletable.not_scoped
        belongs_to :author
      end
    end
    let!(:note_not_scoped) { NoteNotScoped.create!(title: 'note 1') }

    it 'does not include a default scope' do
      expect { note_not_scoped.soft_delete }.not_to change { NoteNotScoped.count }.from(1)
    end

    it 'includes an active scope' do
      expect(NoteNotScoped.active.first).to eq(note_not_scoped)
      note_not_scoped.soft_delete!
      expect(NoteNotScoped.active).to be_empty
    end

    it 'returns self' do
      expect(described_class.not_scoped).to eq(described_class)
    end
  end
end
