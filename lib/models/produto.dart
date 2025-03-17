class Produto 
{
  final int id;
  final String name;
  final String imageUrl;
  final String description;
  final dynamic abv;

  const Produto
  ({
      required this.id,
      required this.name,
      required this.imageUrl,
      required this.description,
      required this.abv
  });
  //                String
  Produto.fromJson(Map<dynamic, dynamic> json)
    : id = json["id"],
      name = json["title"], //[name]
      imageUrl = json["image"].toString(),
      description = json["description"],
      abv = json["abv"];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'image': imageUrl,
    'description': description,
    'abv': abv
  };
}
