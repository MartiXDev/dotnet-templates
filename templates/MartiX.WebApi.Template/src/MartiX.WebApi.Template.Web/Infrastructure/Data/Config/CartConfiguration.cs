using MartiX.WebApi.Template.Web.Domain.CartAggregate;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace MartiX.WebApi.Template.Web.Infrastructure.Data.Config;

public class CartConfiguration : IEntityTypeConfiguration<Cart>
{
  public void Configure(EntityTypeBuilder<Cart> builder)
  {
    builder.Property(entity => entity.Id)
      .HasValueGenerator<VogenGuidIdValueGenerator<AppDbContext, Cart, CartId>>()
      .HasVogenConversion()
      .IsRequired();

    builder.Property(entity => entity.CreatedOn)
      .IsRequired();

    builder.Property(entity => entity.Deleted)
      .IsRequired();

    // CartItems relationship
    builder.HasMany(c => c.Items);
  }
}
