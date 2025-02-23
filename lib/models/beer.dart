class Beer 
{
  final int id;
  final String name;
  final String imageUrl;
  final String description;

  const Beer
  ({
      required this.id,
      required this.name,
      required this.imageUrl,
      required this.description
  });
  //                String
  Beer.fromJson(Map<dynamic, dynamic> json)
    : id = json["id"],
      name = json["title"], //[name]
      imageUrl = json["image"].toString(),
      description = json["description"];
}
