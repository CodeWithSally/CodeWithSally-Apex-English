const members = [
  { name: 'Alice Johnson', image: 'https://mockmind-api.uifaces.co/content/human/217.jpg' },
  { name: 'Bob Smith', image: 'https://mockmind-api.uifaces.co/content/human/222.jpg' },
  { name: 'Marcus Page', image: 'https://mockmind-api.uifaces.co/content/human/80.jpg' },
];

export default function FoundingMembers() {
  return (
    <div className="text-center px-64 py-12">
        <h1 className="text-4xl font-bold text-gray-900 mb-4">Founding Members are:</h1>
        
        <div className="flex justify-center gap-8">
        {members.map((member) => (
          <div key={member.name}>
            <img src={member.image} className="rounded-full w-24 h-24 mx-auto mb-2" />
            <p className="text-gray-700 font-medium">{member.name}</p>
          </div>
        ))}
      </div>
      
    </div>
  );
};