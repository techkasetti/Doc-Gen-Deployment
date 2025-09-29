/**
 * Helper class for scoring entities
 */
private class EntityScore implements Comparable {
    public String entity;
    public Decimal score;
    
    public EntityScore(String entity, Decimal score) {
        this.entity = entity;
        this.score = score;
    }
    
    public Integer compareTo(Object other) {
        EntityScore otherScore = (EntityScore) other;
        if (this.score > otherScore.score) return -1;
        if (this.score < otherScore.score) return 1;
        return 0;
    }
}
