require "faker"

SEED_TAG = "proven_dynamic_catalog_v1".freeze

def purge_seeded_records!
  seeded_user_ids = User.where("email LIKE ?", "seed-%@proven.test").pluck(:id)
  Message.where(sender_id: seeded_user_ids).delete_all
  Conversation.where(buyer_id: seeded_user_ids).or(Conversation.where(maker_id: seeded_user_ids)).find_each(&:destroy!)

  seeded_product_ids = Spree::Product.where("public_metadata @> ?", { seed_tag: SEED_TAG }.to_json).pluck(:id)
  ProductApproval.where(product_id: seeded_product_ids).delete_all
  Spree::Product.where(id: seeded_product_ids).find_each(&:destroy!)

  ShopApproval.joins(:shop).where("shops.name LIKE ?", "Seed Shop %").delete_all
  Shop.where("name LIKE ?", "Seed Shop %").find_each(&:destroy!)
  MakerProfile.where(user_id: seeded_user_ids).delete_all
  User.where(id: seeded_user_ids).find_each(&:destroy!)
end

def ensure_admin_user!
  User.find_or_create_by!(email: "admin@example.com") do |user|
    user.password = "password123"
    user.role = :admin
  end
end

def ensure_spree_dependencies!
  shipping_category = Spree::ShippingCategory.first_or_create!(name: "Default")
  tax_category = Spree::TaxCategory.first_or_create!(name: "Default")
  store = Spree::Store.default || Spree::Store.first
  store ||= Spree::Store.create!(
    name: "Proven Seed Store",
    url: "seed.proven.test",
    mail_from_address: "no-reply@proven.test",
    code: "seed-store",
    default_currency: "USD",
    default: true
  )

  [shipping_category, tax_category, store]
end

def build_seed_makers!(count: 10)
  count.times.map do |index|
    maker = User.create!(
      email: "seed-maker-#{index + 1}@proven.test",
      password: "password123",
      role: :maker
    )

    maker_profile = maker.build_maker_profile(
      display_name: Faker::Name.name,
      country: "United States",
      preferred_currency: "USD",
      bio: Faker::Lorem.sentence(word_count: 20)
    )
    maker_profile.save!(validate: false)

    shop = maker.shops.create!(
      name: "Seed Shop #{index + 1} - #{Faker::Company.unique.name}",
      description: Faker::Lorem.paragraph(sentence_count: 4),
      state: %i[pending approved].sample
    )

    ShopApproval.create!(shop: shop, state: %i[pending approved].sample)
    { maker: maker, shop: shop }
  end
end

def build_seed_buyers!(count: 20)
  count.times.map do |index|
    User.create!(
      email: "seed-buyer-#{index + 1}@proven.test",
      password: "password123",
      role: :buyer
    )
  end
end

def create_seed_product!(maker:, shop:, index:, shipping_category:, tax_category:, store:)
  category = Faker::Commerce.department(max: 1)
  material = %w[Ceramic Linen Wood Cotton Clay Leather Glass].sample
  size_values = %w[Small Medium Large].sample(2)
  color_values = %w[Oat Charcoal Sage Clay Ivory Terracotta].sample(2)
  price_cents = Faker::Number.between(from: 1800, to: 24000)

  product = Spree::Product.new(
    name: Faker::Commerce.unique.product_name,
    description: Faker::Lorem.paragraph(sentence_count: 5),
    slug: "seed-#{shop.id}-#{index}-#{SecureRandom.hex(4)}",
    available_on: Time.current,
    shipping_category: shipping_category,
    tax_category: tax_category,
    status: "draft"
  )

  product.price = (price_cents / 100.0) if product.respond_to?(:price=)
  product.public_metadata = {
    seed_tag: SEED_TAG,
    shop_id: shop.id,
    maker_id: maker.id,
    maker_name: maker.maker_profile&.display_name || maker.email,
    category: category,
    material: material,
    image_url: "https://picsum.photos/seed/proven-#{shop.id}-#{index}/1200/1200",
    price_cents: price_cents,
    variations: {
      size: size_values,
      color: color_values
    }
  }
  product.save!(validate: false)

  if store.present? && defined?(Spree::ProductsStore)
    Spree::ProductsStore.find_or_create_by!(product_id: product.id, store_id: store.id)
  end

  ProductApproval.create!(
    product: product,
    state: %i[pending approved rejected].sample,
    moderation_decision: %w[pending allow review block].sample,
    duplicate_score: rand.round(2)
  )
end

def seed_conversations!(makers:, buyers:)
  makers.each do |entry|
    buyer = buyers.sample
    conversation = Conversation.find_or_create_by!(buyer: buyer, maker: entry[:maker])
    3.times do
      sender = [buyer, entry[:maker]].sample
      conversation.messages.create!(sender: sender, body: Faker::Lorem.sentence(word_count: 14))
    end
  end
end

puts "Purging prior seeded fixtures for #{SEED_TAG}..."
purge_seeded_records!

admin = ensure_admin_user!
shipping_category, tax_category, store = ensure_spree_dependencies!
makers = build_seed_makers!(count: 10)
buyers = build_seed_buyers!(count: 20)

puts "Creating 100 fake products across 10 shops..."
makers.each do |entry|
  10.times do |index|
    create_seed_product!(
      maker: entry[:maker],
      shop: entry[:shop],
      index: index,
      shipping_category: shipping_category,
      tax_category: tax_category,
      store: store
    )
  end
end

seed_conversations!(makers: makers, buyers: buyers)

puts "Seed complete."
puts "- Admin user: #{admin.email}"
puts "- Static admin login: username=Proven_admin password=ProVen0nly10!"
puts "- Shops created: #{Shop.where('name LIKE ?', 'Seed Shop %').count}"
puts "- Seeded products: #{Spree::Product.where('public_metadata @> ?', { seed_tag: SEED_TAG }.to_json).count}"
