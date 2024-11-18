# frozen_string_literal: true

RSpec.describe SoftDelete::Restorable do
  with_model :Note, scope: :all do
    table do |t|
      t.string :title
      t.string :body
      t.datetime :deleted_at
    end

    model do
      include SoftDelete::Restorable
      include SoftDelete::SoftDeletable

      default_scope { where.not(title: nil) }

      validates :body, presence: true
    end
  end

  describe '.deleted' do
    context 'when there is more than one default scope' do
      let!(:without_title) { Note.create(body: 'blah blah', deleted_at: Time.now) }
      let!(:with_title) { Note.create(body: 'blah blah', title: 'some title', deleted_at: Time.now) }

      it 'only removes the default scope associated with deleted_at' do
        expect(Note.deleted.count).to eq(1)
        expect(Note.deleted.first).to eq(with_title)
      end
    end
  end

  describe '#restore_soft_delete' do
    subject { note.restore_soft_delete(validate: validate) }

    let(:note) { Note.create(body: 'blah blah', title: 'some note', deleted_at: Time.now) }
    let(:validate) { true }

    it 'restores the record' do
      expect { subject }.to change { Note.count }.by(1)
    end

    context 'when skipping validations' do
      let(:note) { Note.create(title: 'some note', deleted_at: Time.now) }
      let(:validate) { false }

      it 'restores an otherwise invalid record' do
        expect(note.valid?).to eq(false)
        expect { subject }.to change { Note.count }.by(1)
      end
    end
  end

  describe '#restore with user defined column' do
    around do |example|
      original_column = SoftDelete.configuration.target_column
      SoftDelete.configure do |config|
        config.target_column = :archived_at
      end

      example.run

      SoftDelete.configure do |config|
        config.target_column = original_column
      end
    end

    with_model :TemporaryNote, scope: :all do
      table do |t|
        t.string :title
        t.string :body
        t.datetime :archived_at
      end

      model do
        include SoftDelete::Restorable
        include SoftDelete::SoftDeletable

        default_scope { where.not(title: nil) }

        validates :body, presence: true
      end
    end

    subject { note.restore_soft_delete(validate: validate) }

    let(:note) { TemporaryNote.create(body: 'blah blah', title: 'some note', archived_at: Time.now) }
    let(:validate) { true }

    it 'restores the record' do
      expect { subject }.to change { TemporaryNote.count }.by(1)
    end
  end
end
