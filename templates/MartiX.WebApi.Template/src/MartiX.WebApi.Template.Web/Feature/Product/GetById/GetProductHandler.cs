using MartiX.WebApi.Template.Web.Domain.ProductAggregate;
using MartiX.WebApi.Template.Web.Domain.ProductAggregate.Specifications;
using ProductEntity = MartiX.WebApi.Template.Web.Domain.ProductAggregate.Product;

namespace MartiX.WebApi.Template.Web.Feature.Product.GetById;

public record GetProductQuery(ProductId ProductId) : IQuery<Result<ProductDto>>;

public class GetProductHandler(IReadRepository<ProductEntity> _repository)
  : IQueryHandler<GetProductQuery, Result<ProductDto>>
{
  public async ValueTask<Result<ProductDto>> Handle(GetProductQuery request, CancellationToken cancellationToken)
  {
    var spec = new ProductByIdSpec(request.ProductId);
    var entity = await _repository.FirstOrDefaultAsync(spec, cancellationToken);
    if (entity == null) return Result<ProductDto>.NotFound();

    return new ProductDto(entity.Id, entity.Name, entity.UnitPrice);
  }
}
