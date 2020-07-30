# frozen_string_literal: true
require "byebug"

RSpec.describe SoftDelete::SoftDeletable do
  describe ".dependent" do
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

  describe '#soft_delete' do
    subject { note2.soft_delete }

    with_model :Note, scope: :all do
      table do |t|
        t.string :title
        t.datetime :deleted_at
        t.integer :author_id
      end

      model do
        include SoftDelete::SoftDeletable
        belongs_to :author
      end
    end

    let(:author) { Author.create!(name: 'Stephen') }
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
            end
          end
          let(:author) { Author.create!(name: 'Stephen') }
          let!(:note1) { Note.create!(title: 'note 1', author: author) }
          let!(:note2) { Note.create!(title: 'note 2', author: author) }

          it 'destroys the related records' do
            expect { subject }.to change { Note.unscoped.count }.from(2).to(0)
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

          it 'deletes the related records' do
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

          it 'nullifies the related records' do
            expect { subject }.to change { Note.where(author_id: nil).count }.from(0).to(2)
          end
        end
        context 'when the relation is dependent raise_with_exception'
        context 'when the relation is dependent raise_with_error'
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
            end
          end
          let(:author) { Author.create!(name: 'Stephen') }
          let!(:note1) { Note.create!(title: 'note 1', author: author) }
          let!(:note2) { Note.create!(title: 'note 2', author: author) }

          it 'soft deletes the related records' do
            expect {
              subject
            }.to change { Note.count }.from(2).to(0)
             .and change { Note.unscoped.count }.by(0)
          end
        end
      end
    end
  end
end
