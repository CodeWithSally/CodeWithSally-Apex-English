// Publishes every draft Knowledge article loaded by 02-knowledge-plan.json.
// Tree-imported KnowledgeArticleVersion records always land as Draft
// (SETUP_GUIDE.md #10 "Known Gotchas") — publishing is a workflow action, not
// a field update, so it has to happen here rather than in the tree import.
// Run with: sf apex run --file data/scripts/publish-knowledge-articles.apex --target-org <alias>
List<Knowledge__kav> drafts = [
    SELECT Id, KnowledgeArticleId, Title
    FROM Knowledge__kav
    WHERE PublishStatus = 'draft'
];

Integer publishedCount = 0;
for (Knowledge__kav article : drafts) {
    KbManagement.PublishingService.publishArticle(article.KnowledgeArticleId, true);
    publishedCount++;
}

System.debug('Published ' + publishedCount + ' Knowledge article(s).');
