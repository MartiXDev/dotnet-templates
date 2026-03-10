using MartiX.WebApi.Specifications.EntityFrameworkCore;

namespace MartiX.WebApi.Template.Web.Infrastructure.Data;

// inherit from MartiX.WebApi.Specifications type
public class EfRepository<T>(AppDbContext dbContext) :
  RepositoryBase<T>(dbContext), IReadRepository<T>, IRepository<T> where T : class, IAggregateRoot
{
}
