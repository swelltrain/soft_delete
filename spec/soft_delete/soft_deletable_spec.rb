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
    with_model :Note, scope: :all do
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
    let!(:note) { Note.create!(title: 'note 1') }

    it 'does not include a default scope' do
      expect { note.soft_delete }.not_to change { Note.count }.from(1)
    end

    it 'includes an active scope' do
      expect(Note.active.first).to eq(note)
      note.soft_delete!
      expect(Note.active).to be_empty
    end

    it 'returns self' do
      expect(described_class.not_scoped).to eq(described_class)
    end
  end

  describe '#soft_delete' do
    subject { note2.soft_delete }

    with_model :Note, scope: :all do
      table do |t|
        t.string :title
        t.datetime :deleted_at
        t.integer :author_id
      end

      model do
        # quirk of with_model...
        include SoftDelete::SoftDeletable.scoped
        belongs_to :author
      end
    end

    with_model :Reminder, scope: :all do
      table do |t|
        t.string :title
        t.datetime :deleted_at
        t.integer :author_id
      end

      model do
        # quirk of with_model...
        include SoftDelete::SoftDeletable.scoped
        belongs_to :author
      end
    end

    let!(:note1) { Note.create!(title: 'note 1') }
    let!(:note2) { Note.create!(title: 'note 2') }

    it 'hides the record' do
      expect { subject }.to change { Note.count }.from(2).to(1)
    end

    describe 'dependency behavior' do
      subject { author.soft_delete }
      context 'when dependent default' do
        context 'when the relation is dependent destroy' do
          with_model :Author, scope: :all do
            table do |t|
              t.string :name
              t.datetime :deleted_at
            end

            model do
              include SoftDelete::SoftDeletable.dependent(:default)
              has_many :notes, dependent: :destroy
              has_one :reminder, dependent: :destroy
            end
          end
          let(:author) { Author.create!(name: 'Stephen') }
          let!(:reminder) { Reminder.create!(title: 'reminder', author: author) }
          let!(:note1) { Note.create!(title: 'note 1', author: author) }
          let!(:note2) { Note.create!(title: 'note 2', author: author) }

          it 'destroys the has_many related records' do
            expect { subject }.to change { Note.unscoped.count }.from(2).to(0)
          end

          it 'destroys the has_one related record' do
            expect { subject }.to change { Reminder.unscoped.count }.from(1).to(0)
          end
        end
        context 'when the relation is dependent delete_all' do
          with_model :Author, scope: :all do
            table do |t|
              t.string :name
              t.datetime :deleted_at
            end

            model do
              include SoftDelete::SoftDeletable.dependent(:default)
              has_many :notes, dependent: :delete_all
            end
          end
          let(:author) { Author.create!(name: 'Stephen') }
          let!(:note1) { Note.create!(title: 'note 1', author: author) }
          let!(:note2) { Note.create!(title: 'note 2', author: author) }

          it 'deletes the has_many related records' do
            expect { subject }.to change { Note.unscoped.count }.from(2).to(0)
          end
        end
        context 'when the relation is dependent nullify' do
          with_model :Author, scope: :all do
            table do |t|
              t.string :name
              t.datetime :deleted_at
            end

            model do
              include SoftDelete::SoftDeletable.dependent(:default)
              has_many :notes, dependent: :nullify
            end
          end

          let(:author) { Author.create!(name: 'Stephen') }
          let!(:note1) { Note.create!(title: 'note 1', author: author) }
          let!(:note2) { Note.create!(title: 'note 2', author: author) }

          it 'nullifies the has_many related records' do
            expect { subject }.to change { Note.where(author_id: nil).count }.from(0).to(2)
          end
        end
        context 'when the relation is dependent restrict_with_exception' do
          with_model :Author, scope: :all do
            table do |t|
              t.string :name
              t.datetime :deleted_at
            end

            model do
              include SoftDelete::SoftDeletable.dependent(:default)
              has_many :notes, dependent: :restrict_with_exception
            end
          end
          let(:author) { Author.create!(name: 'Stephen') }
          let!(:note1) { Note.create!(title: 'note 1', author: author) }
          let!(:note2) { Note.create!(title: 'note 2', author: author) }

          it 'raises ActiveRecord::DeleteRestrictionError' do
            expect { subject }.to raise_error(ActiveRecord::DeleteRestrictionError)
          end
        end
        context 'when the relation is dependent restrict_with_error'
      end
      context 'when dependent soft_delete' do
        context 'when the relation is dependent destroy' do
          with_model :Author, scope: :all do
            table do |t|
              t.string :name
              t.datetime :deleted_at
            end

            model do
              include SoftDelete::SoftDeletable.dependent(:soft_delete)
              has_many :notes, dependent: :destroy
              before_destroy :before
              around_destroy :around
              after_destroy :after

              def before; end

              def around; end

              def after; end
            end
          end
          let(:author) { Author.create!(name: 'Stephen') }
          let!(:note1) { Note.create!(title: 'note 1', author: author) }
          let!(:note2) { Note.create!(title: 'note 2', author: author) }

          it 'soft deletes the related records' do
            expect { subject }.to change { Note.count }.from(2).to(0)
                                                       .and change { Note.unscoped.count }.by(0)
          end

          describe 'callbacks' do
            it 'runs the callbacks in order' do
              expect(author).to receive(:before).ordered
              expect(author).to receive(:around).ordered
              expect(author).to receive(:after).ordered
              subject
            end
          end
        end

        context 'when the relation is not using soft delete' do
          with_model :Author, scope: :all do
            table do |t|
              t.string :name
              t.datetime :deleted_at
            end

            model do
              include SoftDelete::SoftDeletable.dependent(:soft_delete)
              has_many :books, dependent: :destroy
            end
          end

          with_model :Book, scope: :all do
            table do |t|
              t.string :title
              t.integer :author_id
            end

            model do
              belongs_to :author
            end
          end

          let(:author) { Author.create!(name: 'Stephen') }
          let!(:book1) { Book.create!(title: 'book 1', author: author) }
          let!(:book2) { Book.create!(title: 'book 2', author: author) }

          it 'raises NoMethodError for soft_delete! on Book' do
            expect { subject }.to raise_error(NoMethodError, /undefined method `soft_delete!'/)
          end
        end

        context 'when the relation is not using soft delete but skipping soft delete for association' do
          with_model :Author, scope: :all do
            table do |t|
              t.string :name
              t.datetime :deleted_at
            end

            model do
              include SoftDelete::SoftDeletable.dependent(
                :soft_delete, skip_dependent_soft_delete: ['Book']
              )
              has_many :books, dependent: :destroy
            end
          end

          with_model :Book, scope: :all do
            table do |t|
              t.string :title
              t.integer :author_id
            end

            model do
              belongs_to :author
            end
          end
          let(:author) { Author.create!(name: 'Stephen') }
          let!(:book1) { Book.create!(title: 'book 1', author: author) }
          it 'should not soft delete the related records' do
            expect { subject }.to change { Book.count }.by(-1)
          end
        end

        context 'when the relation is one to one' do
          with_model :Author, scope: :all do
            table do |t|
              t.string :name
              t.datetime :deleted_at
            end

            model do
              include SoftDelete::SoftDeletable.dependent(:soft_delete)
              has_one :note, dependent: :destroy
            end
          end

          let(:author) { Author.create!(name: 'Stephen') }
          let!(:note1) { Note.create!(title: 'note 1', author: author) }

          it 'should soft delete the related record' do
            expect { subject }.to change { Note.count }.from(2).to(1)
                                                       .and change { Note.unscoped.count }.by(0)
          end
        end
      end
    end
  end

  describe '#user defined column name' do
    subject { note2.soft_delete }

    around do |example|
      original_column = SoftDelete.configuration.target_column
      SoftDelete.configure do |config|
        config.target_column = :archived_at
      end

      example.run

      # Reset to the original configuration after the block
      SoftDelete.configure do |config|
        config.target_column = original_column
      end
    end

    with_model :Note, scope: :all do
      table do |t|
        t.string :title
        t.datetime :archived_at
        t.integer :author_id
      end

      model do
        # quirk of with_model...
        include SoftDelete::SoftDeletable.scoped
        belongs_to :author
      end
    end

    let!(:note1) { Note.create!(title: 'note 1') }
    let!(:note2) { Note.create!(title: 'note 2') }

    it 'hides the record' do
      expect { subject }.to change { Note.count }.from(2).to(1)
      expect(note2.reload.archived_at).not_to be_nil
    end
  end
end
